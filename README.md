# ZuariCPModule-sandbox — SFDX skeleton

This branch contains a minimal Salesforce DX project skeleton under `force-app/main/default`.

Files included:
- `sfdx-project.json` — project config
- `config/project-scratch-def.json` — sample scratch org definition
- `force-app/main/default/classes/HelloWorld.cls` — sample Apex class
- `force-app/main/default/classes/HelloWorld.cls-meta.xml` — Apex metadata
- `.forceignore`, `.gitignore`, `README.md`

Usage:
1. Checkout the branch: `git checkout Dev-Sandeep`
2. Push these files and then run `sfdx` commands locally, e.g.:
   - `sfdx auth:web:login` (or your preferred auth)
   - `sfdx force:org:create -f config/project-scratch-def.json -a MyScratch -s`
   - `sfdx force:source:push`
3. To convert to metadata API (if needed): `sfdx force:source:convert -d mdapi_output_dir -r force-app`

Adjust `sourceApiVersion` and scratch-def settings for your org as required.
