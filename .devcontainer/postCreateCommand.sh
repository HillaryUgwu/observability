#!/usr/bin/env bash

echo 'Running the PostCreateCommand...'

mkdir -p ~/.vscode
cp .devcontainer/keybindings.json ~/.vscode/keybindings.json

# echo "export WORKSPACE_NAME_ID='$CODESPACE_NAME'" >> ~/.envar
bash bin/set_tf_alias
bash bin/install_terraform_cli
# bash ./bin/generate_tfrc_credentials
# cp $CODESPACE_VSCODE_FOLDER/terraform.tfvars.example $CODESPACE_VSCODE_FOLDER/terraform.tfvars
# bash ./bin/build_provider
# bash bin/create_inventory_skeleton_file
