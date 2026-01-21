({
    doInit : function(component, event, helper) {
        // Columns
        component.set("v.columns", [
            { label: 'Name', fieldName: 'Name', type: 'text' },
            { label: 'Owner', fieldName: 'OwnerName', type: 'text' },
          	{ label: 'Allocated Project', fieldName: 'Allocated_Project__c', type: 'text' },
            { label: 'Created Date', fieldName: 'CreatedDate', type: 'date' }
        ]);

        // Load users
        var userAction = component.get("c.getUsers");
        userAction.setCallback(this, function(response){
            if(response.getState() === "SUCCESS"){
                component.set("v.userOptions", response.getReturnValue());
            }
        });
        $A.enqueueAction(userAction);

        // Load picklist values for Allocated Project
        var picklistAction = component.get("c.getAllocatedProjectPicklistValues");
        picklistAction.setCallback(this, function(response){
            if(response.getState() === "SUCCESS"){
                var options = response.getReturnValue().map(function(val){
                    return { label: val, value: val };
                });
                component.set("v.allocatedProjectOptions", options);
            }
        });
        $A.enqueueAction(picklistAction);
    },

    searchRecords : function(component, event, helper) {
        helper.loadRecords(component);
    },

    

    handleRowSelection : function(component, event, helper) {
        var selectedRows = event.getParam("selectedRows");
        component.set("v.selectedIds", selectedRows.map(row => row.Id));
    },

    updateOwner : function(component, event, helper) {
        if(!component.get("v.toUserId")){
            $A.get("e.force:showToast").setParams({
                title: "Error",
                message: "To User is required",
                type: "error"
            }).fire();
            return;
        }
        helper.updateOwnerHelper(component);
    }
})