({
    loadRecords : function(component) {
        var action = component.get("c.fetchRelatedSources");
        action.setParams({
            fromDate           : component.get("v.fromDate"),
            toDate             : component.get("v.toDate"),
           fromUserId         : component.get("v.fromUserId"),
            allocatedProjectValue : component.get("v.allocatedProject")
        });

        action.setCallback(this, function(response){
            if(response.getState() === "SUCCESS"){
                var records = response.getReturnValue();
                records.forEach(function(rec){
                    rec.OwnerName = rec.Owner ? rec.Owner.Name : '';
                });
                component.set("v.records", records);
            }
        });
        $A.enqueueAction(action);
    },

    updateOwnerHelper : function(component) {
    var action = component.get("c.bulkUpdateOwner");
    action.setParams({
        recordIds : component.get("v.selectedIds"),
        toUserId  : component.get("v.toUserId")
    });
    
    action.setCallback(this, function(response){
        if(response.getState() === "SUCCESS"){
            // Show success toast
            $A.get("e.force:showToast").setParams({
                title: "Success",
                message: "Owner updated successfully",
                type: "success"
            }).fire();

            // Refresh entire page
            $A.get('e.force:refreshView').fire();
        } else {
            var errors = response.getError();
            if(errors && errors[0] && errors[0].message){
                alert('Error: ' + errors[0].message);
            }
        }
    });
    $A.enqueueAction(action);
}
})