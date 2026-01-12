public class BookingPDFController {
    public Booking__c booking { get; set; }
    public Co_Applicant__c firstCoApplicant { get; set; }
    public List<String> textLines { get; set; }

    public BookingPDFController(ApexPages.StandardController controller) {
        Id bookingId = controller.getId();
        booking = [SELECT Id, Notes_and_Comments__c, Plot__r.Name, Plot__r.Block_Lookup__r.Name FROM Booking__c WHERE Id = :bookingId];
        system.debug(booking);
        
        if(booking.Notes_and_Comments__c != Null) {
            textLines = booking.Notes_and_Comments__c.split('\r\n');
        } else {
            textLines = new List<String>();
        }

         
        
        List<Co_Applicant__c> coApplicants = [
            SELECT Name, Salutation__c,Date_of_Birth__c,Anniverssary_Date__c,Son_Daughter_Wife_of__c,Nationality__c,	Passport_Number__c,	PAN_Number__c,Email__c,Primary_Phone__c,Residential_Status__c,	Profession__c,	Industry__c,Employeed_at__c,Designation__c
            FROM Co_Applicant__c 
            WHERE Booking__c = :bookingId 
            ORDER BY CreatedDate ASC 
            LIMIT 1
        ];

        if (!coApplicants.isEmpty()) {
            firstCoApplicant = coApplicants[0];
        }
    }
     @AuraEnabled
    public static string sendEmailtoCustomer(String recId)
    {
        Booking__c bk = [SELECT Id, Project__c,Email__c  FROM Booking__c WHERE Id=:recId];
    //    if(qt.Quote_status__c == 'Approved' || qt.Quote_status__c == 'Drafted'){
            Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
            Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
           
   
            PageReference pref;
            pref=page.BookingFormZGC;
            pref.getParameters().put('id',recId);
            pref.setRedirect(true);
            system.debug(pref);
            Blob b;
            
          Boolean isTest = System.Test.isRunningTest();
           if(isTest){
                b = blob.valueOf('Unit.Test');
            }else{
                b = pref.getContent();
            }
            attach.setFileName('Zuari_BookingForm.pdf');
            attach.setBody(b);
            semail.setSubject('Zuari Booking Form');
            
            List<string> sendTo = new List<string>();
            if(bk.Email__c !=null){
                sendTo.add(bk.Email__c);
            }
            
           // if(bk.SLead__r.Secondary_Email__c !=null){
              //  sendTo.add(bk.SLead__r.Secondary_Email__c);
           // }
            system.debug(sendTo);
            semail.setToAddresses(sendTo);
            semail.setHtmlBody('Dear Sir/Madam,<br/> <br/> Thank you very much for your interest in '+bk.Project__c +'.<br/></br>Please find the attached booking form.<br/><b>Note</b>: This is a sample booking from purely for reference.<br/></br>Please feel free to talk us for clarification if any.<br/><br/>Best Regards<br/>Mantri');
            semail.setFileAttachments(new Messaging.EmailFileAttachment[]{attach});
        	system.debug(semail);
            if(sendTo.size()>0){
                try{
                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{semail});
                system.debug(semail);
                 
                }
                
                catch(Exception e){
                    System.debug('Error sending email: ' + e.getMessage());
                }
                
            return 'Booking form sent to customer';    
               
            }else{
                return 'Please enter email address';
            }
     
    }
    
    
    
    
}