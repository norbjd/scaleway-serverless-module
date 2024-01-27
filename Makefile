fmt:
	terraform fmt -recursive .

docs:
	terraform-docs markdown table --output-file README.md --output-mode inject .
