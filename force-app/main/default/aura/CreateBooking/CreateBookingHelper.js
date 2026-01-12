({
    MAX_FILE_SIZE: 4500000, // Max file size 4.5 MB
    CHUNK_SIZE: 750000,      // Chunk Max size 750 KB
    
    addAppliacantRecord: function(component, event, helper) {
        var appList = component.get("v.applicantList");
        appList.push({
            'sObjectType': 'Co_Applicant__c',
            'Salutation__c':"Mr.",
            'Name':'',
            'Date_of_Birth__c':'',
            'Anniverssary_Date__c':'',
            'Son_Daughter_Wife_of__c': '',
            'Nationality__c': '',
            'Passport_Number__c': '',
            //'Aadhar_Number__c': '',
            'PAN_Number__c':'',
            'Email__c': '',
            'Primary_Phone__c': '',
            'Residential_Status__c': '',
            'Profession__c': '',
            'Industry__c': '',
            'Employeed_at__c': '',
            'Designation__c': ''
        });
        component.set("v.applicantList", appList);
    },
    
    uploadHelper1: function(component, event, fileType) {
        //alert('hi');
        //component.set('v.picType', 'PAN_');
        var fileInput = component.find('fuploaders').get('v.files');
        //alert('PAN'+fileInput);
        this.uploadFile(component, event,fileInput,fileType);
    },
    uploadHelper2: function(component, event, fileType) {
        //alert('hi');
        //component.set('v.picType', 'PAN_');
        var fileInput = component.find('fuploaderBack').get('v.files');
        //alert('PAN'+fileInput);
        this.uploadFile(component, event,fileInput,fileType);
    },
    uploadHelper3: function(component, event, fileType) {
        //alert('hi');
        //component.set('v.picType', 'PAN_');
        var fileInput = component.find('fuploadersBack').get('v.files');
        //alert('PAN'+fileInput);
        this.uploadFile(component, event,fileInput,fileType);
    },
    
    uploadFile: function(component, event, fileInput, fileType) {
        //var picType = component.get('v.picType');
        
        var file = fileInput[0];
        var self = this;
        //alert('file'+JSON.stringify(file));
        if (file.size > self.MAX_FILE_SIZE) {
            component.set('v.fileName', 'Alert: File size cannot exceed ' + self.MAX_FILE_SIZE + ' bytes.\n' + 'Selected file size: ' + file.size);
            return;
        }
        
        var objFileReader = new FileReader();
        objFileReader.onload = $A.getCallback(function() {
            var fileContents = objFileReader.result;
            var base64 = 'base64,';
            var dataStart = fileContents.indexOf(base64) + base64.length;
            fileContents = fileContents.substring(dataStart);
            self.uploadProcess(component, file, fileContents, fileType);
        });
        
        objFileReader.readAsDataURL(file);
    },
    
    uploadProcess: function(component, file, fileContents, fileType) {
        var startPosition = 0;
        var endPosition = Math.min(fileContents.length, startPosition + this.CHUNK_SIZE);
        this.uploadInChunk(component, file, fileContents, startPosition, endPosition, '', fileType);
    },
     
    uploadInChunk: function(component, file, fileContents, startPosition, endPosition, attachId, fileType) {
        //alert('Filename'+component.get('v.picType') + file.name);
        var getchunk = fileContents.substring(startPosition, endPosition);
        var action = component.get('c.saveFile');
        action.setParams({
            parentId: component.get('v.bookingid'),
            fileName:  file.name,
            base64Data: encodeURIComponent(getchunk),
            contentType: file.type
            
        });
        
        action.setCallback(this, function(response) {
            attachId = response.getReturnValue();
            var state = response.getState();
            if (state === 'SUCCESS') {
                startPosition = endPosition;
                endPosition = Math.min(fileContents.length, startPosition + this.CHUNK_SIZE);
                if (startPosition < endPosition) {
                    this.uploadInChunk(component, file, fileContents, startPosition, endPosition, attachId);
                } else {
                    this.toastMsg(component, null, null, 'success', 'Success!', 'File has been uploaded successfully');
                }
            } else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log('Error message: ' + errors[0].message);
                    }
                } else {
                    console.log('Unknown error');
                }
            }
        });
        $A.enqueueAction(action);
    },
   
    /*
    uploadInChunk: function(component, file, fileContents, startPosition, endPosition, attachId, fileType) {
        //alert('Filename'+component.get('v.picType') + file.name);
        var getchunk = fileContents.substring(startPosition, endPosition);
        var action = component.get('c.SaveFile');
        action.setParams({
            parentId: component.get('v.recordId'),
            fileName: fileType + file.name,
            base64Data: encodeURIComponent(getchunk),
            contentType: file.type
            
        });
        
        action.setCallback(this, function(response) {
            attachId = response.getReturnValue();
            var state = response.getState();
            if (state === 'SUCCESS') {
                startPosition = endPosition;
                endPosition = Math.min(fileContents.length, startPosition + this.CHUNK_SIZE);
                if (startPosition < endPosition) {
                    this.uploadInChunk(component, file, fileContents, startPosition, endPosition, attachId);
                } else {
                    this.toastMsg(component, null, null, 'success', 'Success!', 'File has been uploaded successfully');
                }
            } else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log('Error message: ' + errors[0].message);
                    }
                } else {
                    console.log('Unknown error');
                }
            }
        });
        $A.enqueueAction(action);
    },
    */
    /*
    validateFields : function(component, event, helper) {
    var book = component.get("v.book");
    var applicantList = component.get("v.applicantList");
    
    // Map of field API names to field labels
    var fieldLabels = {
        'Booking_Date__c': 'Booking Date',
        'Booking_Amount__c': 'Booking Amount',
        'Mode_Of_Payment__c': 'Mode of Payment',
        'Transaction_ID__c': 'Transaction No.',
        'Funding_Type__c': 'Funding Type',
        'Bank_Name__c': 'Bank Name',
        'Branch_Name__c': 'Branch Name',
        'Date_of_Birth1__c':'Date of Birth',
        'First_Applicant_Name__c':'First Applicant Name',
        'Residential_Status__c':'Residential Status',
        'Nationality1__c':'Nationality',
        'PAN_Number__c':'PAN Number',
        'Passport_PI_no__c':'Passport PI no',
        'Mobile__c':'Mobile',
        'Email__c':'Email',
        'Son_Daughter_Wife_of1__c':'Son/Daughter/Wife of',
        'Contact_Telephone_Number1__c':'Contact Telephone Number',
        'Pincode1__c':'Pincode',
        'First_Applicant_Name__c':'First Applicant Name',
        'Permanent_Address1__c':'Permanent Address',
        'Contact_Telephone_Number__c':'Contact Telephone Number',
        'Address__c':'Address',
        'Designation__c':'Designation',
        'Employeed_at__c':'Employeed At',
        'Industry__c':'Industory',
        'Profession__c':'Profession'
    };
    var coappfieldLabels = {
        'Name' : ' Co Applicant Name',
        'Date_of_Birth__c' :'DOB of Co Applicant',
        'Son_Daughter_Wife_of__c' :'Son/Daugher/Wife of',
        'Passport_Number__c' :'Passport Number',
        'Designation__c' : 'Designation',
        'Employeed_at__c' : 'Employeed At',
        'Industry__c' : 'Industry',
        'Profession__c' : 'Profession',
        'Residential_Status__c' : 'Residential Status',
        'Primary_Phone__c' : 'Primary Phone',
        'Email__c': 'Email',
        'PAN_Number__c':'PAN'
    };
    
    // List of mandatory fields
    var mandatoryFields = Object.keys(fieldLabels);
    var mandatoryCoFields = Object.keys(coappfieldLabels);
    // Initialize isValid to true
    var isValid = true;
    
    // Check if any mandatory field is missing
    var missingFields = mandatoryFields.filter(function(field) {
        return !book[field];
    });
        
    // Check if any mandatory field is missing
    var missingCoFields = mandatoryCoFields.filter(function(field) {
        return !applicantList[field];
    });
     alert(missingCoFields)
   
    if (missingFields.length > 0) {
        isValid = false;
        
        // Map missing fields to their labels
        var missingFieldsList = missingFields.map(function(field) {
            return fieldLabels[field];
        }).join(', ');
        
        // Show toast message
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Error",
            "message": "The following  fields are missing: " + missingFieldsList,
            "type": "error"
        });
        toastEvent.fire();
    }
    if (missingCoFields.length > 0) {
        isValid = false;
        
        // Map missing fields to their labels
        var missingFieldsList = missingCoFields.map(function(field) {
            return coappfieldLabels[field];
        }).join(', ');
        
        // Show toast message
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Error",
            "message": "The following mandatory fields are missing: " + missingFieldsList,
            "type": "error"
        });
        toastEvent.fire();
    }
    
    // Additional validation for Nationality-dependent fields
    // 
    
    if (book.Nationality__c === "Indian" && book.Passport_Aadhar_1__c!=null) {
        isValid = false;
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Error",
            "message": "Aadhar No is required for Indian nationality.",
            "type": "error"
        });
        toastEvent.fire();
    } 
        else if (book.Nationality__c === "NRI" && !book.Passport_PI_no__c) {
        isValid = false;
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Error",
            "message": "Passport No is required for NRI nationality.",
            "type": "error"
        });
        toastEvent.fire();
    } 
            else if (book.Nationality__c === "Indian" && !book.PAN_Number__c) {
        isValid = false;
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Error",
            "message": "PAN No is required for Indian nationality.",
            "type": "error"
        });
        toastEvent.fire();
    }
    
   
    return isValid;
},
*/
 validateFields : function(component, event, helper) {
    var book = component.get("v.book");
    var applicantList = component.get("v.applicantList");

    var fieldLabels = {
        'Booking_Date__c': 'Booking Date',
        'Booking_Amount__c': 'Booking Amount',
        'Mode_Of_Payment__c': 'Mode of Payment',
        'Transaction_ID__c': 'Transaction No.',
        'Funding_Type__c': 'Funding Type',
        'Bank_Name__c': 'Bank Name',
        'Branch_Name__c': 'Branch Name',
        'Date_of_Birth1__c':'Date of Birth',
        'First_Applicant_Name__c':'First Applicant Name',
        'Residential_Status__c':'Residential Status',
        'Nationality1__c':'Nationality',
        'PAN_Number__c':'PAN Number',
        'Passport_PI_no__c':'Passport PI no',
        'Mobile__c':'Mobile',
        'Email__c':'Email',
        'Son_Daughter_Wife_of1__c':'Son/Daughter/Wife of',
        'Contact_Telephone_Number1__c':'Contact Telephone Number',
        'Pincode1__c':'Pincode',
        'First_Applicant_Name__c':'First Applicant Name',
        'Permanent_Address1__c':'Permanent Address',
        'Contact_Telephone_Number__c':'Contact Telephone Number',
        'Address__c':'Correspondence Address',
        'Designation__c':'Designation',
        'Employeed_at__c':'Employeed At',
        'Industry__c':'Industry',
        'Aadhaar_Uploaded__c':'Aadhaar Uploaded',
        'PAN_Uploaded__c':'PAN Uploaded',
        'Profession__c':'Profession'
    };

    var coappfieldLabels = {
        'Name' : 'Co Applicant Name',
        'Date_of_Birth__c' :'DOB of Co Applicant',
        'Son_Daughter_Wife_of__c' :'Son/Daughter/Wife of',
        'Passport_Number__c' :'Passport Number',
        'Designation__c' : 'Designation',
        'Employeed_at__c' : 'Employeed At',
        'Industry__c' : 'Industry',
        'Profession__c' : 'Profession',
        'Residential_Status__c' : 'Residential Status',
        'Primary_Phone__c' : 'Primary Phone',
        'Email__c': 'Email',
        'PAN_Number__c':'PAN'
    };

    var mandatoryFields = Object.keys(fieldLabels);
    var mandatoryCoFields = Object.keys(coappfieldLabels);

    var isValid = true;

    // Validate main applicant fields
    var missingFields = mandatoryFields.filter(function(field) {
        return !book[field];
    });

    if (missingFields.length > 0) {
        isValid = false;
        var missingFieldsList = missingFields.map(function(field) {
            return fieldLabels[field];
        }).join(', ');

        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Error",
            "message": "The following fields are missing: " + missingFieldsList,
            "type": "error"
        });
        toastEvent.fire();
    }

    // Validate co-applicant fields only if applicants are added
    if (applicantList.length > 0) {
        var missingCoFieldsList = [];

        applicantList.forEach(function(applicant, index) {
            var missingFields = mandatoryCoFields.filter(function(field) {
                return !applicant[field];  // Ensure each applicant's fields are checked
            });

            if (missingFields.length > 0) {
                var missingFieldsNames = missingFields.map(function(field) {
                    return coappfieldLabels[field];
                }).join(', ');

                missingCoFieldsList.push("Co-Applicant " + (index + 1) + ": " + missingFieldsNames);
            }
        });

        if (missingCoFieldsList.length > 0) {
            isValid = false;

            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error",
                "message": "The following mandatory fields are missing: \n" + missingCoFieldsList.join('\n'),
                "type": "error"
            });
            toastEvent.fire();
        }
    }

    return isValid;
},

    saveRecord : function(component,event,helper) {
        
        var action = component.get("c.convertQuote");
        var book = component.get("v.book");
        //  alert( JSON.stringify(book))
        
        action.setParams({ 
            recId: component.get("v.recordId"),
            book: component.get("v.book"),
            applicantList : component.get("v.applicantList")
        });
        action.setCallback(this, function(response) {
            var state=response.getState();
            console.log('Response : '+response.getReturnValue()); 
            // alert(state);           
            if(state==='SUCCESS'){
              //  component.set('v.Spinner', false);
                var db = response.getReturnValue();
                //  alert(db);
                if(db.includes('Aadhar number must be 12 digits and checks if the field contains a numeric value..')){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type":'Error',
                        "title": 'Error!',
                        "message":'Aadhar number must be 12 digits and checks if the field contains a numeric value..',
                        "duration":10000
                    });
                    toastEvent.fire();
                }else if(db.includes('Check PAN card format')){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type":'Error',
                        "title": 'Error!',
                        "message":'	Check PAN card format',
                        "duration":10000
                    });
                    toastEvent.fire();
                }else if(db =='Unit not available'){
                    var dismissActionPanel = $A.get("e.force:closeQuickAction");
                    dismissActionPanel.fire();
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type":'Error',
                        "title": 'Error!',
                        "message":'Unit not available',
                        "duration":10000
                    });
                    toastEvent.fire(); 
                }else if(db =='Not approved'){
                    var dismissActionPanel = $A.get("e.force:closeQuickAction");
                    dismissActionPanel.fire();
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type":'Error',
                        "title": 'Error!',
                        "message":'Quote is not approved, you can not create booking',
                        "duration":10000
                    });
                    toastEvent.fire();
                }
                    else{
                        if(db !='' && db !=null){
                            
        component.set('v.bookingid',db);
                           // var adar = component.get("v.Aadhar");
                           // var pan = component.get("v.PAN");
                            
                          //  helper.uploadHelper(component, event, adar+'__');
                          //  helper.uploadHelper1(component, event, pan+'__');
                            
                            
                            var first = component.get("v.fileName");
                            var second = component.get("v.file2ndName");
                            var third = component.get("v.file3rdName");
                            
                            if(first!='No Aadhar Photo..'){
                                
                         helper.uploadHelper(component, event, first+'__');
       
                    }
                    if(second!='No PAN Photo..'){
                         
                         
                         helper.upload2Helper(component, event, second+'__');
       
                    }
                    if(third!='No Third Photo..'){
                           alert(third)
                         
                         helper.upload3Helper(component, event, third+'3__');
       
                    }
                     
                            var navEvt = $A.get("e.force:navigateToSObject");
                            navEvt.setParams({
                                "recordId": db,
                                "slideDevName": "detail"
                            });
                            navEvt.fire();
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "type":'Success',
                                "title": 'Success!',
                                "message":'Booking created successfully',
                                "duration":10000
                            });
                            toastEvent.fire();
                        }
                    }
            }
            /*helper.toastMsg(component, event, helper, "success", "Success!", "Booking creating successfully");
               $A.get("e.force:closeQuickAction").fire();
               $A.get('e.force:refreshView').fire();   
           }
           else{
               component.set('v.Spinner', false);
               helper.toastMsg(component, event, helper, "error", "Error!", "Something went Wrong! Please contact System Admin!");
           }*/
        });
        $A.enqueueAction(action);
    },
    
    
    toastMsg: function(component, event, helper, type, title, msg) {
        var toastEvent = $A.get('e.force:showToast');
        toastEvent.setParams({
            'title': title,
            'type': type,
            'message': msg
        });
        toastEvent.fire();
    },
    
    uploadHelper: function(component, event, fileType) {
        //alert('hi');
        var fileInput = component.find('fuploader').get('v.files');
        
        this.uploadFile(component, event,fileInput,fileType);
    },
    
    upload2Helper: function(component, event, fileType) {
        //alert('hi');
        var fileInput = component.find('fuploader2').get('v.files');
       
        this.uploadFile(component, event,fileInput,fileType);
    },
    
    upload3Helper: function(component, event, fileType) {
        
        var fileInput = component.find('fuploader3').get('v.files');
      
        this.uploadFile(component, event,fileInput,fileType);
    },
})