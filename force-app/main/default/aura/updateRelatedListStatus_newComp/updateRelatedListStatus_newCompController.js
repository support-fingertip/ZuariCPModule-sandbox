({
   doInit: function(component, event, helper) {
    var action = component.get("c.getLeadRecordTypeName");
       
    action.setParams({ relatedSourceId: component.get("v.recordId") });

    action.setCallback(this, function(response) {
        //alert(response.getState());
        if (response.getState() === "SUCCESS") {
            var recordTypeName = response.getReturnValue();
            //alert(JSON.stringify(recordTypeName));
            component.set("v.recordTypeName", recordTypeName.recordTypeName);
            let statusOptions = [];

            if (recordTypeName.recordTypeName === "Pre Sales") {
                if(recordTypeName.profileName != 'Sales' && recordTypeName.profileName != 'Pre Sales'){
                    statusOptions = ["New", "Open", "RNR", "Pre Sales Follow Up", "Allocated", "Site Visit Schedule","Rejected","Unqualified" ];
                }
                else{
                    statusOptions = ["New", "Open", "RNR", "Pre Sales Follow Up", "Allocated", "Site Visit Schedule","Request for Rejection","Unqualified" ];
                }
                
            } else {
                    if(recordTypeName.profileName != 'Sales' && recordTypeName.profileName != 'Pre Sales'){
                        statusOptions = ["New Sales Enquiry","Sales Follow up","SV Completed", "Negotiation","Booked", "Unqualified","Closed Lost" ];
                    }
                    else{
                        statusOptions = ["New Sales Enquiry","Sales Follow up","SV Completed", "Negotiation","Booked","Request for Rejection", "Unqualified" ];
                    }
            }

            component.set("v.statusOptions", statusOptions);
        } else {
            helper.showToast("Error", "Failed to load record type name", "error");
        }
    });

    $A.enqueueAction(action);

        var actionun = component.get("c.getUnqualifiedReasons");
       
        actionun.setCallback(this, function(response) {
            //alert(response.getState());
            if (response.getState() === "SUCCESS") {
                component.set("v.unqualifiedReasons", response.getReturnValue());
            }
        });
        $A.enqueueAction(actionun);
       //Get the Closed Lost Reason
       
        var cactionun = component.get("c.getClosedLostReason");
        cactionun.setCallback(this, function(response) {
            //alert(response.getState());
            if (response.getState() === "SUCCESS") {
                component.set("v.closedLostReasons", response.getReturnValue());
            }
        });
        $A.enqueueAction(cactionun);
       
       //Open Reason
       var openreason = component.get("c.getOpenReason");
        openreason.setCallback(this, function(response) {
            //alert(response.getState());
            if (response.getState() === "SUCCESS") {
                component.set("v.openReasons", response.getReturnValue());
            }
        });
        $A.enqueueAction(openreason);
       //Allocated Reason
        var allreason = component.get("c.getAllocatedReason");
        allreason.setCallback(this, function(response) {
            //alert(response.getState());
            if (response.getState() === "SUCCESS") {
                component.set("v.AllocatedReasons", response.getReturnValue());
            }
        });
        $A.enqueueAction(allreason);
       
       var actionLead = component.get("c.getLeadCurrentStatus");
       actionLead.setParams({ relatedSourceId: component.get("v.recordId") });
       actionLead.setCallback(this, function(response) {
           //alert(response.getState());
           if (response.getState() === "SUCCESS") {
               component.set("v.currentLeadStatus", response.getReturnValue());
           }
       });
       $A.enqueueAction(actionLead);
      
},

    handleStatusChange : function(component, event, helper) {
        
        component.set("v.scheduleDate", null);
        component.set("v.rating", null);
    },

    handleSubmit : function(component, event, helper) {
        const status = component.get("v.leadStatus");
         const currentStatus = component.get("v.currentLeadStatus");
        const scheduleDate = component.get("v.scheduleDate");
       const addNotes = component.get("v.addNotes");
        const selectedReason = component.get("v.selectedReason");
        const selectedOpenReason = component.get("v.selectedOpenReason");
        const selectedAlloctReason = component.get("v.selectedAllocatedReason");
        const othcomment = component.get("v.comment");
        const statusOrder = [
            "New",
            "Open",
            "RNR",
            "Pre Sales Follow Up",
            "Allocated",
            "Site Visit Schedule",
            "New sales enquiry",
            "Sales Follow up",
            "SV Completed",
            "Negotiation",
            "Booked",
            "Request for Rejection",
            "Rejected",
            "Unqualified",
            "Closed Lost"
        ];
        
        // If moving backward → block it
        if (
            currentStatus &&
            statusOrder.indexOf(status) < statusOrder.indexOf(currentStatus)
        ) {
            console.log('error causeed by status change');
            helper.showToast(
                "Error",
                "You cannot move the Realted source status backward from " + currentStatus + " to " + status + ".",
                "error"
            );
            return;
        }

        // Validations
        if (!status || status === '') {
            helper.showToast("Error", "Please select a Lead Status.", "error");
            return;
        }

        if ((status === 'RNR' || status == 'Open' || status == 'Allocated' || status === 'Pre Sales Follow Up' || status === 'Site Visit Schedule'|| status === 'Sales Follow up')  &&  (!scheduleDate || !addNotes)
           ) {
            helper.showToast(
                "Error",
                !scheduleDate
                ? "Schedule Date is required for selected status."
                : "Notes are required for selected status.",
                "error"
            );
            return;
        }
/*
        if (status === 'Unqualified' && (!selectedReason || selectedReason === '')) {
            helper.showToast("Error", "Unqualified Reason is required for Unqualified Related source.", "error");
            return;
        }
        
        if (status === 'Unqualified' && (!selectedReason || selectedReason === 'Other') && (!othcomment || othcomment ==='')) {
            helper.showToast("Error", "Other Reason is required for Unqualified leads.", "error");
            return;
        }
*/
        helper.updateLeadAndRelated(component, status,addNotes, scheduleDate, selectedReason,othcomment,selectedOpenReason,selectedAlloctReason);
    },
    
    handleCancel : function(component, event, helper) {
        component.set("v.isOpen", false);
        $A.get("e.force:closeQuickAction").fire();
    },
     handleReasonChange: function(component, event, helper) {
        var selectedValue = event.getSource().get("v.value");
        component.set("v.selectedReason", selectedValue);
    },
    
    handleclosedReasonChange : function(component, event, helper) {
        
    var selectedReason = component.get("v.selectedReason");
    
    var reasonsRequiringDetail = [
        'Vaastu Concern',
        'Dimension',
        'Loan Eligibility',
        'Duplicate Lead',
        'Already Allocated',
        'Booked With Competitor',
        'Booked With Zuari',
        'Not A Valid Customer',
        'Not In Location',
        'Not In Size',
        'Not Interested',
        'CP Clash',
        'Junk Leads'
    ];
    
    var showDetail = reasonsRequiringDetail.includes(selectedReason);
       // alert(showDetail)
    component.set("v.showDetailReason", showDetail);
},

})