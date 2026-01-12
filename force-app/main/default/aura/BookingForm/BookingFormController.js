({
	 doInit : function(component, event, helper) {
        
      component.set('v.showPdf',true);
                //var vfpage = '/apex/'+Quote__c+'?Id='+component.get('v.recordId');
			 var vfpage = 'https://zuari--c.vf.force.com/apex/BookingFormZGC?id='+component.get('v.recordId');	
               // var vfpage='https://platform-connect-8636--sbox1.sandbox.lightning.force.com/lightning/r/Quote__c/'+'?Id='+component.get('v.recordId');
         component.set('v.vfPage',vfpage);
            },
    send: function(component,event,helper){
        var action = component.get("c.sendEmailtoCustomer");
        action.setParams({"recId":component.get("v.recordId")});
        action.setCallback(this,function(response){
            if(response.getState() == 'SUCCESS' ) {
                
                var res_string= response.getReturnValue();
                event.stopPropagation();
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
                var type;
                if(res_string == 'Booking form sent to customer'){
                    //system.debug(res_string);
                    type = 'success';
                }
                else{
                    type = 'error';
                }
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type":type,
                    "title": type,
                    "message":res_string,
                    "duration":10000
                });
                toastEvent.fire();
                $A.get('e.force:refreshView').fire();
            }
            else
            {
                (state === 'ERROR')
                {
                    console.log('failed');
                }
            }
        });
        $A.enqueueAction(action);
    },
    close : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
      sendEmail : function(component, event, helper) {
          
        component.set("v.isPopup", true);
    },
    closeModal : function(component, event, helper) {
        // Close the confirmation modal
        component.set("v.isPopup", false);
    },	
       // });
       //$A.enqueueAction(action);
})