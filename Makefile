# Create the Client 'manage-themes' in the Admin workspace with the application type Service.
# Confirm these OAuth settings after you have created the client:
#
#  Grant Types: Client Credentials
#  Response Types: Token
#  Token Endpoint Authentication Method: Client Secret Post
#
# Create a file named Makefile.inc that overrides the following example values:
#
CLIENT_ID	= PUT_YOUR_CLIENT_ID_HERE
CLIENT_SECRET	= PUT_YOUR_CLIENT_SECRET_HERE
TENANT_ID	= your-tenant
SERVER_ID	= your-workspace-id
ISSUER_URL	= https://your-tenant.your-region.authz.cloudentity.io/your-tenant/admin
THEME_ID	= demo
#
# Set TENANT_ID and ISSUER_URL appropriately for your client.
# Your client should be in the 'admin' workspace, but SERVER_ID can be any workspace
# that you wish to bind themes to, such as 'default' or 'demo'.

# This Makefile uses features that are not available from MacOS /bin/sh.
SHELL		= /bin/bash

# Load the overrides from Makefile.inc, and fetch an OAuth2 token.
include Makefile.inc
BASEURL        := $(shell egrep -o 'https://[^/]+' <<<'${ISSUER_URL}')
TOKEN          := $(shell curl -sSLk -X POST ${ISSUER_URL}/oauth2/token \
			--header "Content-Type: application/x-www-form-urlencoded" \
			--data-urlencode "grant_type=client_credentials"  \
			--data-urlencode "client_id=${CLIENT_ID}" \
			--data-urlencode "client_secret=${CLIENT_SECRET}" \
                        | jq -r .access_token)

# Set some default values
CURL		= curl -sSLk
TEMPLATE_PATH  	= pages/authorization/login/scripts.tmpl

# 'make all' will create the default theme (demo), upload its templates,
# and bind it to the tenant and workspace specified by TENANT_ID and SERVER_ID.
all:	create-theme upsert-templates bind-theme

# Note that the tenant_id in THEME_JSON, will be replaced by the URL path parameter.
THEME_JSON   	= {"tenant_id":"${TENANT_ID}", "id":"${THEME_ID}", "name":"${THEME_ID}"}

# 'make create-theme' will create the 'demo' theme by default.
# 'make create-theme THEME_ID=torgue' will create a new theme named "torgue".
create-theme:
	${CURL} -D - -X POST '${BASEURL}/api/admin/${TENANT_ID}/theme' \
	--header 'Authorization: Bearer ${TOKEN}' \
	--header 'Content-Type: application/json' \
	--data   '${THEME_JSON}'

# Note that, as with create-theme, the values in BINDING_JSON  will be preempted by URL path parameters.
BINDING_JSON   	= {"wid":"${SERVER_ID}", "theme_id":"${THEME_ID}"}

# 'make bind-theme' will bind the 'demo' theme by default.
# 'make bind-theme THEME_ID=torgue SERVER_ID=demo' will bind theme "torgue" to the demo workspace.
bind-theme:
	${CURL} -D - -X POST '${BASEURL}/api/admin/${TENANT_ID}/servers/${SERVER_ID}/bind-theme/${THEME_ID}' \
	--header 'Authorization: Bearer ${TOKEN}' \
	--header 'Content-Type: application/json' \
	--data   '${BINDING_JSON}'

# 'make unbind-them' will unbind whatever theme is bound to the workspace, or 404 if there is no binding.
unbind-theme:
	${CURL} -D - -X POST '${BASEURL}/api/admin/${TENANT_ID}/servers/${SERVER_ID}/unbind-theme' \
	--header 'Authorization: Bearer ${TOKEN}' \
	--header 'Content-Type: application/json' \
	--data   '{"wid":"${SERVER_ID}"}'

# 'make delete-theme' will delete the 'demo' theme by default, and all its templates.
delete-theme:
	${CURL} -D - -X DELETE '${BASEURL}/api/admin/${TENANT_ID}/theme/${THEME_ID}' \
	--header 'Authorization: Bearer ${TOKEN}'

# 'make upsert-templates' will create/update the 'demo' templates by default.
upsert-templates:
	for f in $$(cd theme; find * -name '*.tmpl'); \
        do  make upsert-template THEME_ID=${THEME_ID} TEMPLATE_PATH="$$f" TOKEN=${TOKEN} ; \
	done

# To update a specific template, for example:
# make upsert-template TEMPLATE_PATH=pages/authorization/login/scripts.tmpl
upsert-template:
	${CURL} -D - -X PUT '${BASEURL}/api/admin/${TENANT_ID}/theme/${THEME_ID}/template/${TEMPLATE_PATH}' \
	--header 'Authorization: Bearer ${TOKEN}' \
	--header 'Content-Type: application/json' \
	--data-binary @<(jq -M --raw-input --slurp < 'theme/${TEMPLATE_PATH}' '{"content":.}')

# To delete a specific template, for example:
# make delete-template TEMPLATE_PATH=pages/authorization/login/scripts.tmpl
delete-template:
	${CURL} -D - -X DELETE '${BASEURL}/api/admin/${TENANT_ID}/theme/${THEME_ID}/template/${TEMPLATE_PATH}' \
	--header 'Authorization: Bearer ${TOKEN}' \
	--header 'Content-Type: application/json'

# 'make get-theme' will fetch the 'demo' theme by default.
get-theme:
	${CURL} -X GET '${BASEURL}/api/admin/${TENANT_ID}/theme/${THEME_ID}' \
	--header 'Authorization: Bearer ${TOKEN}' \
	| jq -M

# 'make get-templates' will list the 'demo' theme's templates by default.
get-templates:
	${CURL} -X GET '${BASEURL}/api/admin/${TENANT_ID}/theme/${THEME_ID}/templates' \
	--header 'Authorization: Bearer ${TOKEN}' \
	| jq -M

# 'make list-base-templates' will list all of the built-in templates.
list-base-templates:
	${CURL} -X GET '${BASEURL}/api/admin/${TENANT_ID}/themes/templates' \
	--header 'Authorization: Bearer ${TOKEN}' \
	| jq -M

# 'make export-templates' will download the theme templates in ZIP format.
export-templates:
	${CURL} -X GET '${BASEURL}/api/admin/${TENANT_ID}/theme/${THEME_ID}/templates/zip' \
	--header 'Authorization: Bearer ${TOKEN}' -o ${THEME_ID}.zip
	unzip -l ${THEME_ID}.zip

# 'make import-templates' will upload the theme templates in ZIP format, eg 'demo.zip'
import-templates:
	${CURL} -D - -X POST '${BASEURL}/api/admin/${TENANT_ID}/theme/${THEME_ID}/templates/zip' \
	--header 'Authorization: Bearer ${TOKEN}' \
	--header 'Content-Type: application/zip' \
	--data-binary @${THEME_ID}.zip



get-servers:
	${CURL} -X GET '${BASEURL}/api/admin/${TENANT_ID}/servers' \
	--header 'Authorization: Bearer ${TOKEN}' \
	| jq -M '.servers[] | [ .id, .theme_id ]'

phony:
	egrep -o '^[a-z0-9-]+:' Makefile | egrep -o '^[^:]+' | sort | xargs echo '.PHONY:' >> Makefile

.PHONY: all bind-theme create-theme delete-theme export-templates get-servers get-templates get-theme import-templates list-base-templates phony unbind-theme upsert-template upsert-templates
