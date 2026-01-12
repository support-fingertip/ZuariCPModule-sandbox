# ZuariCPModule-Sandbox — Salesforce DX project

This repository contains the initial Salesforce DX scaffold for the Zuari CP Module (sandbox). Files were prepared for branch `Praveen_dev_zuariCp`.

Default configuration:
- SFDX project (source format)
- API version: 60.0
- Scratch org edition: Developer

Quickstart:
1. Clone the repo and checkout the branch:
   git checkout Praveen_dev_zuariCp
2. Create a scratch org (example):
   sfdx force:org:create -f config/project-scratch-def.json -s -a zuari-sandbox
3. Push source:
   sfdx force:source:push
4. Open org:
   sfdx force:org:open

If you want a Metadata (mdapi) layout instead of SFDX source format, or prefer a different API version or scratch org edition, tell me and I'll adjust before pushing.
