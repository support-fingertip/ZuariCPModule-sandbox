({
 updateLeadAndRelated : function(component, status,addNotes, scheduleDate, selectedReason,othcomment,selectedOpenReason,selectedAlloctReason) {
    console.log("entered helper sending data to apex" +addNotes );
    const action = component.get("c.updateLeadWithStatus");
    action.setParams({
        relatedSourceId: component.get("v.recordId"),
        status: status,
        lastnote : addNotes,
        scheduleDate: scheduleDate,
        rating: selectedReason,
        openreason: selectedOpenReason,
        alloctreason: selectedAlloctReason,
        othercom : othcomment
    });

    action.setCallback(this, function(response) {
        const state = response.getState();
        if (state === "SUCCESS") {
            var responseMessage = response.getReturnValue();
           // alert(responseMessage);
            if(responseMessage == 'Updated Successfully'){
                
            $A.get("e.force:showToast").setParams({
                "title": "Success",
                "message": "Related source Status Updated Successfully!",
                "type": "success"
            }).fire();
                
            $A.get("e.force:closeQuickAction").fire();
            $A.get('e.force:refreshView').fire();
                if(status=='Unqualified' || status=='Closed Lost'){
                    
                 window.location.href = '/lightning/o/Related_Source__c/home';
                }
            }
            else if (responseMessage.includes('Please select future date / time') || responseMessage.includes('Please enter future Date')) {
                     $A.get("e.force:showToast").setParams({
                        "title": "Validation Error",
                        "message": 'Choose Future Date and Time',
                        "type": "warning"
                    }).fire();
                   
                }
                else {
                    let errors = response.getError();
                    let errorMessage = "Unknown error";
                    
                    if (errors && errors.length > 0) {
                        errorMessage = errors[0].message;
                    }
                    
                    $A.get("e.force:showToast")
                    .setParams({
                        "title": "Error",
                        "message": errorMessage,
                        "type": "error"
                    })
                    .fire();
                }
                        
            
            
        } else {
            let errors = response.getError();
            console.error(errors);

            let errorMsg = "Something went wrong.";
            if (errors && errors[0] && errors[0].message) {
                errorMsg = errors[0].message;

                if (errorMsg.includes("Please select future date / time")) {
                    // Show validation toast if future date message
                    $A.get("e.force:showToast").setParams({
                        "title": "Validation Error",
                        "message": errorMsg,
                        "type": "warning"
                    }).fire();
                    return;
                }
            }

            // Default error toast
            $A.get("e.force:showToast").setParams({
                "title": "Error",
                "message": errorMsg,
                "type": "error"
            }).fire();
        }
    });

    $A.enqueueAction(action);
},

    showToast: function(title, message, type) {
        var toastEvent = $A.get("e.force:showToast");
        if (toastEvent) {
            toastEvent.setParams({
                "title": title,
                "message": message,
                "type": type,
                "mode": "dismissible"
            });
            toastEvent.fire();
        } else {
            alert(title + ': ' + message); // fallback for classic / debug mode
        }
    }
})