// This file is part of scaleway-serverless-module-validator (https://github.com/norbjd/scaleway-serverless-module/validator).
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
	"encoding/json"
	"errors"
	"fmt"
	"os"

	"github.com/hashicorp/hcl/v2"
	"github.com/hashicorp/hcl/v2/hclsyntax"
	"github.com/zclconf/go-cty/cty"
	"gopkg.in/yaml.v3"
)

var errCannotAccessEnvFile = errors.New("cannot access env file")

// readVariablesFromEnvFile - parse a YAML file (only string values) to a map
func readVariablesFromEnvFile(envFile string) (map[string]string, error) {
	variables := make(map[string]string)

	_, err := os.Stat(envFile)
	if err != nil {
		return nil, fmt.Errorf("%w: %s", errCannotAccessEnvFile, err)
	}

	envFileContents, err := os.ReadFile(envFile)
	if err != nil {
		return nil, fmt.Errorf("cannot read %s: %w", envFile, err)
	}

	if err = yaml.Unmarshal(envFileContents, variables); err != nil {
		return nil, fmt.Errorf("env file %s is invalid: %w", envFile, err)
	}

	return variables, nil
}

// yamlToJSON - convert a YAML string to JSON
func yamlToJSON(y string) (string, error) {
	m := map[string]interface{}{}

	if err := yaml.Unmarshal([]byte(y), &m); err != nil {
		return "", fmt.Errorf("invalid yaml: %w", err)
	}

	jsonContents, err := json.Marshal(m)
	if err != nil {
		return "", fmt.Errorf("internal error: %w", err)
	}

	return string(jsonContents), nil
}

// terraformTemplateFile - equivalent to templatefile function from terraform: https://github.com/hashicorp/terraform/blob/v1.7.1/internal/lang/funcs/filesystem.go#L72-L192
func terraformTemplateFile(contentsToTemplate []byte, variables map[string]string) (string, error) {
	var err error

	expr, diags := hclsyntax.ParseTemplate(contentsToTemplate, "", hcl.Pos{Line: 1, Column: 1, Byte: 0})
	if diags.HasErrors() {
		for _, e := range diags.Errs() {
			err = errors.Join(err, e)
		}
		return "", err
	}

	ctx := &hcl.EvalContext{
		Variables: map[string]cty.Value{},
	}

	for k, v := range variables {
		ctx.Variables[k] = cty.StringVal(v)
	}

	for _, traversal := range expr.Variables() {
		root := traversal.RootName()
		if _, ok := ctx.Variables[root]; !ok {
			err = errors.Join(err, fmt.Errorf("- env does not contain key %q, referenced at %s", root, traversal[0].SourceRange()))
		}
	}
	if err != nil {
		return "", fmt.Errorf("missing variables (have you passed the correct env file?): \n%w", err)
	}

	val, diags := expr.Value(ctx)
	if diags.HasErrors() {
		for _, e := range diags.Errs() {
			err = errors.Join(err, e)
		}
		return "", fmt.Errorf("error while templating: %w", err)
	}

	return val.AsString(), nil
}
