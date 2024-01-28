// This file is part of scaleway-serverless-module-validator (https://github.com/norbjd/scaleway-serverless-module/scaleway-serverless-module-validator).
//
// Copyright (C) 2024 norbjd
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, version 3 of the License.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

package main

import (
	"errors"
	"flag"
	"fmt"
	"log"
	"os"

	"github.com/xeipuuv/gojsonschema"
)

func main() {
	var (
		moduleVersion   string
		contextDir      string
		configFilename  string
		envFilename     string
		localJSONSchema string
	)

	flag.StringVar(&moduleVersion, "module-version", "main", "OPTIONAL: module version to check against")
	flag.StringVar(&localJSONSchema, "json-schema", "", "OPTIONAL: JSON schema to validate against. If not specified, will download the JSON schema with version specified in -module-version")

	flag.StringVar(&contextDir, "context-dir", ".", "OPTIONAL: path to context dir (same as context_dir variable in the module)")
	flag.StringVar(&configFilename, "config-file-name", "scaleway_serverless_config.yaml", "OPTIONAL: YAML config file name")
	flag.StringVar(&envFilename, "env-file-name", ".scaleway_serverless_config.env.yaml", "OPTIONAL: env file name")

	flag.Parse()

	pathToJSONSchema := fmt.Sprintf(
		"https://raw.githubusercontent.com/norbjd/scaleway-serverless-module/%s/scaleway-serverless-module-validator/config_json_schema.json",
		moduleVersion,
	)

	if localJSONSchema != "" {
		pathToJSONSchema = fmt.Sprintf("file://%s", localJSONSchema)
	}

	log.Println("checking config validity against:", pathToJSONSchema)

	configFile := contextDir + "/" + configFilename
	envFile := contextDir + "/" + envFilename

	contents, err := os.ReadFile(configFile)
	if err != nil {
		log.Fatalln("can't read config file:", err.Error())
	}

	log.Println("config file used is:", configFile)

	variables, err := readVariablesFromEnvFile(envFile)
	if err != nil {
		if errors.Is(err, errCannotAccessEnvFile) {
			log.Printf("cannot access env file %s (%s), but will continue\n", envFile, err)
		} else {
			log.Fatalln("cannot read variables from env file", err)
		}
	}

	yamlTemplated, err := terraformTemplateFile(contents, variables)
	if err != nil {
		log.Fatalf("cannot template yaml: %s", err.Error())
	}

	jsonConfig, err := yamlToJSON(yamlTemplated)
	if err != nil {
		log.Fatalln(err)
	}

	schemaLoader := gojsonschema.NewReferenceLoader(pathToJSONSchema)
	documentLoader := gojsonschema.NewStringLoader(jsonConfig)

	result, err := gojsonschema.Validate(schemaLoader, documentLoader)
	if err != nil {
		log.Fatalln("cannot validate config file: ", err.Error())
	}

	if result.Valid() {
		log.Println("config is valid")
		return
	}

	log.Println("found some errors:")
	for _, desc := range result.Errors() {
		log.Printf("- %s\n", desc)
	}
	log.Fatalln("invalid config")
}
