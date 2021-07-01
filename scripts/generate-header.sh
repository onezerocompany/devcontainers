#!/bin/sh
echo "" >> /.header
echo "~~~ Welcome to the Deno Developer Environment ~~~" >> /.header
echo "" >> /.header
echo "==== Runtime Versions ====" >> /.header
deno --version >> /.header
echo "node $(node -v)" >> /.header
echo "--- Tool Versions ---" >> /.header
echo "npm > $(npm -v)" >> /.header
echo "prettier > $(prettier -v)" >> /.header
echo "eslint > $(eslint -v)" >> /.header
echo "___ config versions ___" >> /.header
echo "eslint-config > $(npm view -g @onezerocompany/eslint-config version)" >> /.header
echo "prettier-config > $(npm view -g @onezerocompany/prettier-config version)" >> /.header
echo "tsconfig-node > $(npm view -g @onezerocompany/tsconfig-node version)" >> /.header
echo "" >> /.header
echo "Have fun coding :)" >> /.header
echo "" >> /.header