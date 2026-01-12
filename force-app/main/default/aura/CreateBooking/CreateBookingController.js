({
    doInit: function(component, event, helper) {
        //  component.set('v.Spinner', true); 
       
        // var prd = component.get("v.prd") || {};

        
        component.set('v.showCostSheet',true);
        
        var action = component.get("c.quoteRecord");
        action.setParams({ 
            recId: component.get("v.recordId")
        });
        
        action.setCallback(this, function(response) {
            var state=response.getState();
            console.log('Response : '+response.getReturnValue()); 
            
            if(state==='SUCCESS'){
                var qt = response.getReturnValue();
                var booking = component.get('v.book');
                component.set('v.quote',qt);
                component.set('v.book',booking);
                var book = component.get("v.book");
                var unitstatus = qt.Unit__r.Status__c;
                if(unitstatus == 'Booked'){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error",
                        "message": "Booking already created for this Unit.",
                        "type": "error"
                    });
                    toastEvent.fire(); 
                    var dismissActionPanel = $A.get("e.force:closeQuickAction");
                    dismissActionPanel.fire();
                }
                    book.Plot__c	 = qt.Unit_Number__c;	
                 book.Wing__c	 = qt.Wing__c;	
                book.Rate_per_sqft__c	 = qt.Rate_per_sqft__c;	
                book.Email__c = qt.SLead__r.Email;
                book.Agreement_Value_Before_GST__c = qt.Agreement_Value_Before_GST__c;
                book.Project__c	 = qt.Project__c;
                //alert( JSON.stringify(book))
                component.set('v.book',book);
                
            }
            component.set("v.isModalOpen", true);
        });
        $A.enqueueAction(action);
    },
    
     handleEmailChange: function(component, event, helper) {
        var newEmail = event.getSource().get("v.value");
        component.set("v.PEmail", newEmail);
    },
    
    
    
    
    closeModel: function(component, event, helper) {
        // Set isModalOpen attribute to false  
        
        component.set("v.isModalOpen", false);
        $A.get("e.force:closeQuickAction").fire();
    },
    save: function(component, event, helper) {
        var adar = component.get("v.book.Aadhaar__c");
        
        if(helper.validateFields(component,event,helper)) {
            // If validation passes, call the helper function to save the record
            helper.saveRecord(component,event,helper);
        }
    },
    
    
    handleaddSecondApplicant: function(component, event, helper) {
        
        component.set("v.show2nd", true);
    },
    
    handleremoveSecondApplicant: function(component, event, helper) {
        
        component.set("v.show2nd", false);
    },
    validateMarriageAnniversaryDate: function(component, event, helper) {
        var selectedItem = event.currentTarget;
        var index = selectedItem.dataset.record;
        var applicantList = component.get("v.applicantList");
        var prd = applicantList[index];
        var marriageAnniversaryDate = prd.Anniverssary_Date__c;
        
        if (marriageAnniversaryDate) {
            var selectedDate = new Date(marriageAnniversaryDate);
            var currentDate = new Date();
            
            selectedDate.setHours(0, 0, 0, 0);
            currentDate.setHours(0, 0, 0, 0);
            if (selectedDate > currentDate) {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error",
                    "message": "Please select past date",
                    "type": "error"
                });
                toastEvent.fire(); 
                prd.Marriage_Anniversary_Date__c = null;  
                component.set("v.applicantList", applicantList);  
            } else {
                component.set("v.applicantList", applicantList);  
            }
        }
    },
    validateMarriageAnniversaryDateBooking: function(component, event, helper) {
        
        var dateOfBirth = component.get("v.book.Anniverssary_Date1__c");
        
        if (dateOfBirth) {
            var selectedDate = new Date(dateOfBirth);
            var currentDate = new Date();
            
            selectedDate.setHours(0, 0, 0, 0);
            currentDate.setHours(0, 0, 0, 0);
            
            if (selectedDate > currentDate) {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error",
                    "message": "Please select past date",
                    "type": "error"
                });
                toastEvent.fire(); 
                component.set("v.book.Marriage_anniversary_date__c", null);
            } 
        }
    },
    validateDOB: function(component, event, helper) {
        var applicantList = component.get("v.applicantList");
        var selectedItem = event.currentTarget;
        var index = selectedItem.dataset.record;
        var prd = applicantList[index];
        var dateOfBirth = prd.Date_of_Birth__c;
        
        if (dateOfBirth) {
            var birthDate = new Date(dateOfBirth);
            var currentDate = new Date();
            var age = currentDate.getFullYear() - birthDate.getFullYear();
            var m = currentDate.getMonth() - birthDate.getMonth();
            
            if (m < 0 || (m === 0 && currentDate.getDate() < birthDate.getDate())) {
                age--;
            }
            if (age < 18) {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error",
                    "message": "Age should more than 18.",
                    "type": "error"
                });
                toastEvent.fire(); 
                prd.Date_of_Birth__c = null; 
                component.set("v.applicantList", applicantList); 
            } else {
                component.set("v.applicantList", applicantList); 
            }
        }
    },
   
    validatePhone: function(component, event, helper) {
        var phoneField = component.find("v.book.Mobile__c");
       // var phoneValue = phoneField.get("v.value");

        let phoneRegex = /^[0-9]{10,}$/; // Allows only numbers and minimum 10 digits

        if (!phoneRegex.test(phoneField)) {
            phoneField.setCustomValidity("Enter a valid 10-digit phone number.");
        } else {
            phoneField.setCustomValidity(""); // Clears error if valid
        }
        phoneField.reportValidity();
    },

    

    validateAge : function(component, event, helper) {
        var dateOfBirth = component.get("v.book.Date_of_Birth1__c");
        
        if (dateOfBirth) {
            var birthDate = new Date(dateOfBirth);
            var currentDate = new Date();
            var age = currentDate.getFullYear() - birthDate.getFullYear();
            var m = currentDate.getMonth() - birthDate.getMonth();
            
            if (m < 0 || (m === 0 && currentDate.getDate() < birthDate.getDate())) {
                age--;
            }
            
            
            if (age < 18) {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error",
                    "message": "Age should more than 18.",
                    "type": "error"
                });
                toastEvent.fire(); 
                component.set("v.book.Date_of_Birth__c", null);
            } 
        }
    },
    handleaddThirdApplicant: function(component, event, helper) {
        
        component.set("v.show3rd", true);
    },
    handleremoveThridapplicant: function(component, event, helper) {
        
        component.set("v.show3rd", false);
    },
    
    handleFilesChangePhoto: function(component, event, helper) {
        var fileName = 'No File Selected..';
        if (event.getSource().get("v.files").length > 0) {
            fileName = event.getSource().get("v.files")[0]['name'];
        }
        component.set("v.fileName", fileName);
        
    },
    handleFilesChange2ndPhoto: function(component, event, helper) {
        var fileName = 'No File Selected..';
        if (event.getSource().get("v.files").length > 0) {
            fileName = event.getSource().get("v.files")[0]['name'];
        }
        component.set("v.file2ndName", fileName);
        
    },
    handleFilesChange3rdPhoto: function(component, event, helper) {
        var fileName = 'No File Selected..';
        if (event.getSource().get("v.files").length > 0) {
            fileName = event.getSource().get("v.files")[0]['name'];
        }
        component.set("v.file3rdName", fileName);
        
    },
    handleNationalityChange : function(component, event, helper) {
        var nationality = component.get("v.book.Nationality__c");
        if (nationality === "Indian") {
            component.set("v.isAadharRequired", true);
            component.set("v.isPanRequired", true);
            component.set("v.isPassportRequired", false);
        } else if (nationality === "NRI") {
            component.set("v.isAadharRequired", false);
            component.set("v.isPanRequired", false);
            component.set("v.isPassportRequired", true);
        }
    },
    removeRow : function(component, event, helper) {
        var selectedItem = event.currentTarget;
        var index = selectedItem.dataset.record;
        var aitems= component.get('v.applicantList');
        //alert(index);
        aitems.splice(index, 1);
        component.set("v.applicantList", aitems);
        /*if(aitems.length < 1){
            helper.addAppliacantRecord(component, event, helper);
        }*/
    },
    addRow: function(component, event, helper) { 
        helper.addAppliacantRecord(component, event, helper);
    },
    validateTransactionNo: function(component, event, helper) {
        var inputField = event.getSource();
        var value = inputField.get("v.value");
        
        // Allow only alphanumeric (A-Z, a-z, 0-9)
        var alphanumericRegex = /^[a-zA-Z0-9]*$/;
        
        if (value && !alphanumericRegex.test(value)) {
            inputField.setCustomValidity("Only letters and numbers are allowed (no spaces or symbols).");
        } else {
            inputField.setCustomValidity(""); // Clear error
        }
        inputField.reportValidity();
    },
    
    formatPassport: function(component, event, helper) {
        var passportField = event.getSource();
        var passportValue = passportField.get("v.value");
        
        if (passportValue) {
            passportField.set("v.value", passportValue.toUpperCase()); // Force uppercase
        }
    },
    formatPAN: function(component, event, helper) {
        var panField = event.getSource();
        var panValue = panField.get("v.value");
        
        if (panValue) {
            panField.set("v.value", panValue.toUpperCase()); // Force uppercase
        }
    },

})