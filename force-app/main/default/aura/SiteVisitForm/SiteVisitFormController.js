({
    doInit : function(component, event, helper) {
        var action = component.get("c.getProjectPicklistValues");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.projects", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
        
        var action1 = component.get("c.getCountryAndCode");
        //alert(action);
        action1.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var countryMap = response.getReturnValue();
                component.set("v.sectionLabels", countryMap);
            }
            
        });
        $A.enqueueAction(action1);
    },
    checkLead : function(component, event, helper) {
        var selectedProject = component.get("v.selectedProject");
        var phone = component.get("v.phone");
        
        // Validation for mandatory fields
        if (!selectedProject) {
            helper.toastMsg('Error', 'Validation Error', 'Please select a project.');
            return;
        }
        if (!phone) {
            helper.toastMsg('Error', 'Validation Error', 'Please enter a phone number.');
            return;
        }
        
        var action = component.get("c.checkLeadWithPhoneProject");
        action.setParams({ "project_name": selectedProject, "phone_number": phone });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var leadDetailsString = response.getReturnValue();
                var leadDetails = JSON.parse(leadDetailsString);
                var otpStatus = leadDetails.OTPStatus;
                
                component.set("v.leadName", leadDetails.leadname);
                component.set("v.phonenumer", leadDetails.phone);
                component.set("v.otpStatus", leadDetails.OTPStatus);
                component.set("v.leadId", leadDetails.leadId);
                component.set("v.showDetails", true);
                var now = new Date();
                component.set("v.datevalue", now.toISOString());
                //alert(otpStatus);
                if (otpStatus == 'Lead Exists And Not Active' || otpStatus == 'Lead Exist In Active Status') {
                    var action1 = component.get("c.getLead");
                    action1.setParams({ "leadId": leadDetails.leadId });
                    action1.setCallback(this, function(response) {
                        var state = response.getState();
                        if (state === "SUCCESS") {
                            //alert(JSON.stringify(response.getReturnValue()))
                            component.set('v.leadRecord', response.getReturnValue());
                            component.set("v.leadRecordToSave",response.getReturnValue());
                            if (otpStatus == 'Lead Exists And Not Active') {
                                helper.toastMsg('Success', 'Related Source Status', 'Related Source Exists And Not Active');
                            }
                            else if(otpStatus == 'Lead Exist In Active Status'){
                                helper.toastMsg('Success', 'Related Source Status', 'Related Source Exist In Active Status');
                            }
                        }
                    });
                    $A.enqueueAction(action1);
                }
                
                if (otpStatus == 'Lead Exists But NO Active OTP Exist') {
                    helper.toastMsg('Warning', 'Related Source Status', 'Related Source is in Inactive Status');
                }
                if (otpStatus == 'No Lead Exists') {
                    helper.toastMsg('Error', 'Related Source Status', 'No Related Source Exists');
                }
                if (otpStatus == 'SV Already Conducted') {
                    helper.toastMsg('Error', 'Related Source Status', 'Site Visit Already Conducted');
                }
            }
        });
        $A.enqueueAction(action);
    },
    
    clearValues : function(component, event, helper) {
        component.set("v.selectedProject",'None');
        component.set("v.phone",'');
    },
    handleCountryChange: function(component, event, helper) {
        var selectedUnitId = component.find("CountryLookupField").get("v.value");
        var countryMap = component.get("v.sectionLabels");
        console.log(JSON.stringify(countryMap));
        var selectedCountryCode = countryMap[selectedUnitId];
        component.set("v.selectedCountryCode", selectedCountryCode);
        
    },
    handleError: function (cmp, event, helper) {
        var error = event.getParams();
        var errorMessage = event.getParam("message");
        if(errorMessage=='The requested resource does not exist'){
            helper.toastMsg('error','Duplicate','Related Source already exist in the system');
            cmp.set('v.proceedEvenIfExisingLead',true);
        }else{
            helper.toastMsg('error','Error',errorMessage);
        }
    },
    handleSubmit : function(component, event, helper) {
        event.preventDefault();
        var leadName = component.find("leadName").get("v.value");
        var leadFirstName = component.find("leadFirstName").get("v.value");
        var salutation = component.find("salutation").get("v.value");
        const primaryphone =component.get("v.phone");
        // alert(leadName);
        var pattern = /^[A-Za-z ]+$/;
        
        if(!pattern.test(leadName)|| !pattern.test(leadFirstName)) {
            component.set("v.isSubmitting", false);
            //  alert("Please enter alphabets only in Name!");
            helper.toastMsg('Warning','Name','Please enter alphabets only in Name!');
            return; // Do not submit if invalid
        }
        if (!salutation) {
            component.set("v.isSubmitting", false);
            helper.toastMsg('Warning', 'Salutation', 'Please select a Salutation!');
            return;
        }
        
        
        
        
        var eventFields = event.getParam("fields");
        
        let formDataSnapshot = JSON.parse(JSON.stringify(eventFields));
        
        formDataSnapshot.Salutation = salutation;
        formDataSnapshot.FirstName = leadFirstName;
        formDataSnapshot.LastName = leadName;
        
        formDataSnapshot.Country_Code__c = component.get('v.selectedCountryCode');
        
        component.set('v.formDataSnapshot', formDataSnapshot);
        component.set('v.isDuplicateError', true);
        
        
        
        var ldSr = component.get('v.leadSource');
        if(ldSr == 'Direct Walkin'){
            eventFields["Campaign_Type__c"] = 'Walkin';
            eventFields["Sub_Source__c"] = 'Direct Walkin';
        }
        if(ldSr == 'Referral'){
            eventFields["Campaign_Type__c"] = 'Organic';
            eventFields["Sub_Source__c"] = 'Client Referral';
        }
        eventFields["Lead_source__c"] = ldSr;
        eventFields["Country_Code__c"] = component.get('v.selectedCountryCode');
        eventFields["Country_Code__c"] = component.get('v.selectedCountryCode');
        //eventFields.LastName = leadName;
        //eventFields.Phone__c = primaryphone;
        //eventFields.FirstName = leadFirstName;
        //eventFields.Salutation = salutation;
        // // Build combined full name safely (skip blanks)
        var fullName = '';
        if (salutation) {
            fullName += salutation + ' ';
        }
        if (leadFirstName) {
            fullName += leadFirstName + ' ';
        }
        if (leadName) {
            fullName += leadName;
        }
        
        // Trim any extra space at the end
        fullName = fullName.trim();
        
        // Set the final name into Name__c
        eventFields["Name__c"] = fullName;
        eventFields.Walking_Lead_Form__c = true;
        
        component.find('myform').submit(eventFields);
        
    },
    handleSuccess : function(component, event, helper) {
        var record = event.getParam("response");
        var apiName = record.apiName;
        var myRecordId = record.id;
        component.set('v.spinner',false);
        var action = component.get("c.leadNotExists");
        action.setParams({
            "leadId" : myRecordId
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state == 'SUCCESS') {
                helper.toastMsg('Success','Success','Related Source successfully');
                var selected = '1';
                component.find("tabs").set("v.selectedTabId", selected);
                component.set("v.otpStatus",null);
                component.set("v.showDetails",false);
                
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    "recordId": myRecordId,
                    "slideDevName": "detail"
                });
                navEvt.fire();
                
            }else{
                helper.toastMsg('Error','Error','Something Went Wrong')
            }
        });
        $A.enqueueAction(action);
        
    },
    duplicateLeadSaving : function(component, event, helper) {
        var action = component.get("c.duplicateLeadExists");
        action.setParams({
            "leadDetails" : component.get("v.formDataSnapshot")
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state == 'SUCCESS') {
                helper.toastMsg('Success','OTP Status','Related Source Saved Successfully');
                var selected = '1';
                component.find("tabs").set("v.selectedTabId", selected);
                component.set("v.otpStatus",null);
                component.set("v.showDetails",false);
                component.set("v.phone",'');
                component.set("v.selectedProject",'');
                
            }else{
                alert('Something Went Wrong');
            }
        });
        $A.enqueueAction(action);
    },
    svWithLead : function(component, event, helper) {
        let isAllValid = component.find('field123').reduce(function (isValidSoFar, inputCmp) {
            inputCmp.showHelpMessageIfInvalid();
            return isValidSoFar && inputCmp.checkValidity();
        }, true);
        
        if (isAllValid == true) {
            //alert(JSON.stringify(component.get('v.leadRecordToSave')));
            var action = component.get("c.leadExists");
            action.setParams({
                
                "otp" : component.get("v.phone"),
                "phone_number" : component.get("v.phone"),
                "project_name" : component.get("v.selectedProject"),
                "svDate" : component.get("v.datevalue"),
                "visitType" : component.get("v.visitType"),
                "leadRec": component.get('v.leadRecordToSave')
            });
            action.setCallback(this, function(response){
                var state = response.getState();
                if(state == 'SUCCESS') {
                    var db = response.getReturnValue();
                    if(db == 'OTP Matched'){
                        helper.toastMsg('Success','OTP Status','Related Source Details Saved Successfully');
                        var selected = '1';
                        component.find("tabs").set("v.selectedTabId", selected);
                        component.set("v.otpStatus",null);
                        component.set("v.showDetails",false);
                        component.set("v.phone",'');
                        component.set("v.selectedProject",'');
                    }
                    else if(db == 'OTP Not Matched'){
                        helper.toastMsg('Error','OTP Status','OTP Not Matched');
                    }
                        else if(db == 'OTP Validated'){
                            helper.toastMsg('Success','OTP Status','Site Visit Verified Successfully');
                            var selected = '1';
                            component.find("tabs").set("v.selectedTabId", selected);
                            component.set("v.otpStatus",null);
                            component.set("v.showDetails",false);
                        }
                }else{
                    alert('Something Went Wrong');
                }
            });
            $A.enqueueAction(action);
            
            
            
        }
    },
    isChannelPartner: function(component, event, helper) {
        var eventFields = event.getParam("fields");
        var source = component.get("v.leadSource");
        if(source == "Channel Partner"){
            component.set('v.isChannelPartner',true);
        }
        else{
            component.set('v.isChannelPartner',false);
        }
        
    }
})