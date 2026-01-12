import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createChannelPartner from '@salesforce/apex/ChannelPartnerController.createChannelPartner';
import saveFileToRecord from '@salesforce/apex/ChannelPartnerController.saveFileToRecord';

export default class ChannelPartnerForm extends LightningElement {
    @track showAlert = false;
    @track alertMessage = '';
    @track alertClass = '';
    @track alertIcon = '';
    @track recordId = null;
    @track isSaving = false;
    @track showForm = true;

    @track formData = {
        Company_Name__c: '',
        Company_Head_Name__c: '',
        Company_Owner_Name__c: '',
        Team_Strength__c: '',
        Company_Website__c: '',
        Email__c: '',
        Company_Head_Email_ID__c: '',
        Company_Owner_Email_ID__c: '',
        Company_Head_Contact_No__c: '',
        Company_Owner_Contact_No__c: '',
        Company_Address__c: '',
        City__c: '',
        City_you_reside_in__c: '',
        Select_Region__c: '',
        Company_GST_No__c: '',
        Company_PAN_Card_No__c: '',
        PAN_Card_No__c: '',
        Company_RERA_No__c: '',
        RERA_Validity__c: ''
    };

    @track uploadStatus = {
        gst: '',
        pan: '',
        rera: '',
        aadhar: '',
        other: ''
    };

    get saveButtonLabel() {
        return this.isSaving ? 'Saving...' : 'Save Application';
    }

    handleInputChange(event) {
        const field = event.target.name;
        const value = event.target.value;
        this.formData[field] = value;
    }

    async handleSave() {
        // Validate required fields
        const allValid = [...this.template.querySelectorAll('lightning-input, lightning-textarea')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);

        if (!allValid) {
            this.showAlertMessage('Please fill all required fields correctly.', 'error');
            return;
        }

        this.showAlert = false;
        this.isSaving = true;

        try {
            // Convert formData to plain object for Apex
            const fieldValues = {};
            Object.keys(this.formData).forEach(key => {
                if (this.formData[key]) {
                    fieldValues[key] = this.formData[key];
                }
            });

            const result = await createChannelPartner({ fieldValues });
            this.recordId = result;
            this.isSaving = false;
            this.showForm = false;

            this.showAlertMessage(
                `Application saved successfully! Reference ID: ${this.recordId}. You can now upload documents below.`, 
                'success'
            );
            
            this.toast('Success', `Record created with ID: ${this.recordId}`, 'success');

            // Scroll to top to show success message
            window.scrollTo({ top: 0, behavior: 'smooth' });

        } catch (error) {
            this.isSaving = false;
            const msg = this.extractErrorMessage(error);

            this.showAlertMessage(msg, 'error');
            this.toast('Error', msg, 'error');

            console.error('CreateRecord error:', JSON.stringify(error));
            window.scrollTo({ top: 0, behavior: 'smooth' });
        }
    }

    async handleFileUpload(event) {
        const files = event.target.files;
        if (!files || files.length === 0) return;

        const documentType = event.target.dataset.documentType;
        const MAX_FILE_SIZE = 4500000; // ~4.5MB (stay under 5MB governor limit)

        for (let i = 0; i < files.length; i++) {
            const file = files[i];

            // Validate file size
            if (file.size > MAX_FILE_SIZE) {
                this.toast('File Too Large', `${file.name} exceeds 4.5MB limit`, 'error');
                continue;
            }

            try {
                const base64 = await this.readFileAsBase64(file);
                
                await saveFileToRecord({
                    recordId: this.recordId,
                    fileName: file.name,
                    base64Data: base64,
                    contentType: file.type
                });

                // Update upload status
                this.updateUploadStatus(documentType, file.name);
                
                this.toast('Upload Complete', `${documentType}: ${file.name} uploaded successfully`, 'success');

            } catch (error) {
                const msg = error.body?.message || error.message || 'File upload failed';
                this.toast('Upload Error', `${file.name}: ${msg}`, 'error');
                console.error('File upload error:', error);
            }
        }

        // Clear the file input
        event.target.value = null;
    }

    readFileAsBase64(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => {
                const base64 = reader.result.split(',')[1];
                resolve(base64);
            };
            reader.onerror = () => reject(reader.error);
            reader.readAsDataURL(file);
        });
    }

    updateUploadStatus(documentType, fileName) {
        switch(documentType) {
            case 'GST Certificate':
                this.uploadStatus.gst = `✓ ${fileName}`;
                break;
            case 'PAN Card':
                this.uploadStatus.pan = `✓ ${fileName}`;
                break;
            case 'RERA Certificate':
                this.uploadStatus.rera = `✓ ${fileName}`;
                break;
            case 'Aadhar Card':
                this.uploadStatus.aadhar = `✓ ${fileName}`;
                break;
            case 'Other Document':
                this.uploadStatus.other = this.uploadStatus.other 
                    ? `${this.uploadStatus.other}, ${fileName}` 
                    : `✓ ${fileName}`;
                break;
        }
    }

    extractErrorMessage(error) {
        if (!error) return 'Unknown error occurred';

        // Handle AuraHandledException
        if (error.body?.message) {
            return error.body.message;
        }

        // Handle standard error message
        if (error.message) {
            return error.message;
        }

        // Handle field errors
        if (error.body?.output?.fieldErrors) {
            const fieldErrors = error.body.output.fieldErrors;
            const firstField = Object.keys(fieldErrors)[0];
            if (firstField && fieldErrors[firstField]?.length) {
                return `${firstField}: ${fieldErrors[firstField][0].message}`;
            }
        }

        // Handle page errors
        if (error.body?.output?.errors?.length) {
            return error.body.output.errors[0].message;
        }

        // Handle page-level errors
        if (error.body?.pageErrors?.length) {
            return error.body.pageErrors[0].message;
        }

        return 'An error occurred. Please check all fields and try again.';
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant,
            mode: variant === 'error' ? 'sticky' : 'dismissable'
        }));
    }

    showAlertMessage(message, type) {
        this.alertMessage = message;
        this.showAlert = true;

        if (type === 'success') {
            this.alertClass = 'slds-notify slds-notify_alert slds-alert_success slds-m-bottom_medium';
            this.alertIcon = 'utility:success';
        } else {
            this.alertClass = 'slds-notify slds-notify_alert slds-alert_error slds-m-bottom_medium';
            this.alertIcon = 'utility:error';
        }
    }

    closeAlert() {
        this.showAlert = false;
    }

    resetAll() {
        // Reset all form data
        this.formData = {
            Company_Name__c: '',
            Company_Head_Name__c: '',
            Company_Owner_Name__c: '',
            Team_Strength__c: '',
            Company_Website__c: '',
            Email__c: '',
            Company_Head_Email_ID__c: '',
            Company_Owner_Email_ID__c: '',
            Company_Head_Contact_No__c: '',
            Company_Owner_Contact_No__c: '',
            Company_Address__c: '',
            City__c: '',
            City_you_reside_in__c: '',
            Select_Region__c: '',
            Company_GST_No__c: '',
            Company_PAN_Card_No__c: '',
            PAN_Card_No__c: '',
            Company_RERA_No__c: '',
            RERA_Validity__c: ''
        };

        // Reset upload status
        this.uploadStatus = {
            gst: '',
            pan: '',
            rera: '',
            aadhar: '',
            other: ''
        };

        // Reset other flags
        this.recordId = null;
        this.isSaving = false;
        this.showAlert = false;
        this.showForm = true;

        // Reset file inputs
        const fileInputs = this.template.querySelectorAll('input[type="file"]');
        fileInputs.forEach(input => {
            input.value = null;
        });

        // Scroll to top
        window.scrollTo({ top: 0, behavior: 'smooth' });

        this.toast('Reset Complete', 'Form cleared. You can create a new application.', 'info');
    }
}