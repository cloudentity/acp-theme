# acp-theme

Theme templates and CLI tool for managing custom branding of ACP authorization and identity pool views

## How create an ACP theme and bind it to a workspace (using ACP Admin UI)

- In the Admin UI of your ACP SaaS tenant, go to the actions menu in the upper right, and select "Appearance"
- Select "Create Theme"
- After creating your theme, locate your new theme in the list of themes
- From the three-dot action menu of the new theme, select "Bind to Workspace" and select the workspace you want to use with the theme

## How to work with these templates

> **Note:** ACP uses Golang templates to render Theme views. See the [Go docs](https://pkg.go.dev/text/template) for info on template syntax.

The templates in this repository are organized in the same file structure as the templates you can edit in the ACP Admin UI theme editor.

The easiest/safest method to make theme modifications is to edit templates first in this repository, using your preferred code editor. Then, use the CLI instructions below to upload the theme template(s) to ACP. Using the CLI, is possible to upload individual templates (useful when testing changes in development on specific views), or to upload the entire theme (useful when migrating the entire theme to a new tenant/workspace).

While it is possible to edit theme templates directly in ACP's Admin UI tool, this is recommended only for experimenting with a non-production "sandbox" theme, as it can be hard to track/compare/revert changes this way. By managing theme templates in this external repository, it's possible to track commit history, tag versions, easily revert if necessary, and quickly migrate a theme to a different tenant.

If a situation comes up in which it's absolutely necessary for someone to make a change to a template in the ACP Admin UI tool, make sure the change gets synced with this repository as soon as possible.

**IMPORTANT!** Uploading any changes will make those changes instantly visible for anyone who has access to the tenant/workspace associated with the theme configured in your CLI settings, so if there is a theme that is being used in production, make sure to verify changes in a dev workspace/theme first before deploying the changes to the prod theme.

## How to use the Makefile/CLI

You will need to create an ACP Client named 'manage-themes' in the Admin workspace with the application type `Service`.

> Note: If the `Service` application type is not available, in the Admin workspace, navigate to "Auth Setttings > OAuth," and under "Allowed Grant types," make sure "Client credentials" is selected.

Confirm these OAuth settings after you have created the client:

* Grant Types: Client Credentials
* Response Types: Token
* Token Endpoint Authentication Method: Client Secret Post

Now create a file named `Makefile.inc` that overrides the following default values:
```
CLIENT_ID	= PUT_YOUR_CLIENT_ID_HERE
CLIENT_SECRET	= PUT_YOUR_CLIENT_SECRET_HERE
TENANT_ID	= your-tenant
SERVER_ID	= your-workspace-id
ISSUER_URL	= https://your-tenant.your-region.authz.cloudentity.io/your-tenant/admin
THEME_ID	= demo
THEME_DIR = theme
```

**IMPORTANT:** When working with a "vanity domain" that does not have a tenant ID in the URL params for API requests, leave the value of the `TENANT_ID` variable blank in the `Makefile.inc`, and set the value of `ISSUER_URL` without the `TENANT_ID` param, as shown below:

```
TENANT_ID	=
ISSUER_URL	= https://vanity-domain.your-organization.com/admin
```

> **Note:** `SERVER_ID` refers to the ID of the workspace to which you intend to bind your theme.

The `THEME_DIR` value indicates which directory should be used as the local source of the templates when 'upsert' commands are used. When creating a custom theme, it is possible to leave the default theme unedited as a reference, and set up a custom theme directory with a copy of the whole theme (or containing only a subset of templates to be altered, as long as the directory structure matches that of the default theme). In this case, change the value of `THEME_DIR` to the path of your custom directory. For example, this could be something like `my-custom-themes/demo-theme-1`, where `my-custom-themes` is located in the project root, and with `demo-theme-1` containing the `pages` and `shared` directories, etc.

To test that the makefile is working, you can do `make list-base-templates` to query ACP:
```
$ make list-base-templates
curl -sSLk -X GET 'https://host.docker.internal:8443/api/admin/default/themes/templates' \
	--header 'Authorization: Bearer ...' \
	| jq -M
{
  "fs_paths": [
    "pages/authorization/ciba/simulator/index.tmpl",
    "pages/authorization/consent/index.tmpl",
    "pages/authorization/demo/index.tmpl",
    ...
```

The other targets in the Makefile can be used to manage the theme and its templates:

- `make create-theme` will create the "demo" theme by default.
- `make bind-theme` will bind the "demo" theme by default.
- `make unbind-theme` will unbind whatever theme is bound to the workspace, or 404 if there is no binding.
- `make delete-theme` will delete the "demo" theme by default, and all its templates.
- `make upsert-templates` will create/update the "demo" templates by default.
- `make get-theme` will fetch the "demo" theme by default.
- `make get-templates` will list the "demo" theme's templates by default.
- `make list-base-templates` will list all of the built-in templates.
- `make export-templates` will download the theme templates in ZIP format.
- `make import-templates` will upload the theme templates in ZIP format, eg "demo.zip".

For all of these targets, you can override the values of THEME_ID and TEMPLATE PATH.
For example:

- `make create-theme THEME_ID=example-theme` will create a new theme named "example-theme".
- `make upsert-template TEMPLATE_PATH=pages/authorization/login/scripts.tmpl` will upsert the specified template.
- `make delete-template TEMPLATE_PATH=pages/authorization/login/scripts.tmpl` will delete the specified template.
