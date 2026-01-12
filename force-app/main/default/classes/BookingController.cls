public without sharing class BookingController {
    /*  
@auraEnabled
public static string convertQuote(string recId, Date bookingDate,Decimal bookingAmount,string paymentMode,string fundingType,String myRecordId){
system.debug(recId);
Quote__c qt = [SELECT Id,Name,SLead__c,SLead__r.Email,Approval_status__c,Quote_status__c,
Maintenance_Charge__c,Corpus_Fund__c,Built_up_area__c,Basic_Price__c,Payment_Type__c,
Infrastructure_Charges_per_sqft__c,Project__c,Property_Type__c,Unit__c,Lead__r.Name,
SLead__r.Secondary_Email__c,Plot_Type__c,Plot_Land_Area__c,
GST1__c,Apartment_No__c,Token_Amount__c,Quote_date__c,Maintenance_Deposite__c,Other_Charges_Payable_on_Possession__c,
Floor_Rise_Charges_Rate__c,Premium_Charge__c,Clubhouse_Charges__c,BESCOM_Deposit_Rs__c,
Legal_Documentation_Charges__c,Development_Charge__c,Block_Lookup__c FROM Quote__c WHERE Id=:recId];
Project__c pro = [select id,name,CRM_executive__c from Project__c where Project__c =: qt.Project__c];
system.debug(recId);
if(qt.Quote_status__c=='sent to customer'){
system.debug(bookingAmount);
system.debug(paymentMode);
Booking__c bk = new Booking__c();
bk.Id = myRecordId;
bk.Quote__c = qt.Id;
bk.SLead__c = qt.SLead__c;
bk.Project__c = qt.Project__c;
bk.Booking_Date__c = bookingDate;
bk.Plot__c = qt.Unit__c;
bk.CRM_Manager__c = pro.CRM_executive__c;
bk.Block__c=qt.Block_Lookup__c;
bk.Booking_Amount__c = bookingAmount;
bk.Funding_Type__c = fundingType;
bk.Date_of_Booking__c =bookingdate;
bk.Plot_Land_Area__c=qt.Plot_Land_Area__c;
bk.GST__c=qt.GST1__c;
bk.Apartment_Number__c=qt.Apartment_No__c;
bk.Payment_Type__c=qt.Payment_Type__c;
bk.Mode_Of_Payment__c = paymentMode;
bk.Maintenance_Charge__c=qt.Maintenance_Charge__c;
bk.Legal_Documentation_Charges__c=qt.Legal_Documentation_Charges__c;
bk.Corpus_Fund__c=qt.Corpus_Fund__c;
bk.Email__c = qt.SLead__r.Email;
bk.Email__c = qt.SLead__r.Email;
bk.Email1__c=qt.SLead__r.Secondary_Email__c;
bk.Applicant_Mobile_Number__c =qt.Lead__r.Phone__c;
bk.Applicant_Name__c = qt.Lead__r.Name;
bk.Club_House__c= qt.Clubhouse_Charges__c;
bk.Infrastructure_Charges_per_sqft__c=qt.Infrastructure_Charges_per_sqft__c;
upsert bk;

Lead ld = new Lead();
ld.Id=qt.SLead__c;
ld.Unit_No__c=qt.Unit__c;
ld.Lead_Status__c='Booked';
ld.RecordTypeId=Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
//update ld;

Quote__c quot = new Quote__c();
quot.Id = qt.Id;
quot.Quote_status__c = 'Converted';
update quot;

plot__c pt=new plot__c();
pt.id = qt.Unit__c;
System.debug('samp2'+pt.Id);
pt.Status__c='Blocked';
if(pt.Id!=null){
update pt;
}
return bk.Id;
}
else{
return 'Not approved';
}
}
*/ 
    @AuraEnabled
    public static List<String> getPaymentTypePicklistValues() {
        List<String> paymentTypeValues = new List<String>();
        Schema.DescribeFieldResult fieldResult = Booking__c.Mode_Of_Payment__c.getDescribe();
        
        for (Schema.PicklistEntry picklistEntry : fieldResult.getPicklistValues()) {
            paymentTypeValues.add(picklistEntry.getLabel());
        }
        
        return paymentTypeValues;
    }
    
    @AuraEnabled
    public static List<String> getFundingtTypePicklistValues() {
        List<String> paymentTypeValues = new List<String>();
        Schema.DescribeFieldResult fieldResult = Booking__c.Funding_Type__c.getDescribe();
        
        for (Schema.PicklistEntry picklistEntry : fieldResult.getPicklistValues()) {
            paymentTypeValues.add(picklistEntry.getLabel());
        }
        
        return paymentTypeValues;
    }
    
    @AuraEnabled
    public static Quote__c quoteRecord(String recId) {
        Quote__c qt = [select id,name,/*Booking_Amount__c,Basic_Villa_Cost__c, Project_Type__c,RecordType.Name,Basic_Flat_Cost__c,   Block_Lookup__r.Name*/ Unit_Number__c,Unit__r.Unit_Facing_Direction__c, Unit__r.Status__c, Project__c,Wing__c,Block__c,Agreement_Value_Before_GST__c,SLead__r.Email,Rate_per_sqft__c  from Quote__c where Id=:recId ];
        return qt;
    }
    @AuraEnabled
    public static void changeUnitStatus(Map<Id,String> plotIds){
        List<Plot__c> plotList = [Select Id,Name,Status__c from Plot__c where Id in: plotIds.keySet()];
        for(Plot__c plt : plotList){
            plt.Status__c = plotIds.get(plt.Id);
        }
        update plotList;
    }
    /*
    @AuraEnabled
    public static void requestSaleAgreement(Id recId){
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Sale Agreement');
        req1.setObjectId(recId);
        req1.setSubmitterId(userInfo.getUserId()); 
        req1.setProcessDefinitionNameOrId('Request_For_Sale_Agreement');
        req1.setSkipEntryCriteria(true);
        Approval.ProcessResult result = Approval.process(req1);
    }
    @AuraEnabled
    public static void bookingCancellationApproval(Id recId){
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Booking Cancellation');
        req1.setObjectId(recId);
        req1.setSubmitterId(userInfo.getUserId()); 
        req1.setProcessDefinitionNameOrId('Cancellation_Approval_For_Booking');
        req1.setSkipEntryCriteria(true);
        Approval.ProcessResult result = Approval.process(req1);
    }
    
    public static void bookingSwappingApproval(Id recId){
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Booking Swapping');
        req1.setObjectId(recId);
        req1.setSubmitterId(userInfo.getUserId()); 
        req1.setProcessDefinitionNameOrId('Swapping_Approval_process');
        req1.setSkipEntryCriteria(true);
        Approval.ProcessResult result = Approval.process(req1);
    }
    */
    
    public static void chnageUnitStatus(List<Booking__c> bookList) {   
    Set<Id> units = new Set<Id>();
    for (Booking__c bcc : bookList) {
        units.add(bcc.Plot__c);
    }
    List<Plot__c> plotList = [SELECT Id, Name, Status__c FROM Plot__c WHERE Id IN :units];
    for (Plot__c plt : plotList) {
        plt.Status__c = 'Available';
    }
    if (!plotList.isEmpty()) {
        update plotList;
    }
}



    
  /*  
    public static void swapUnit(List<Booking__c> swappingBookings){
        Set<Id> Bookunits = new Set<Id>();
        Set<Id> AvaiUnits = new Set<Id>();
        List<Booking__c> newBookings = new List<Booking__c>();
        for(Booking__c book : swappingBookings){
            Bookunits.add(book.Swap_Unit__c);
            AvaiUnits.add(book.Plot__c);
            Booking__c newBook = book.clone(false,false,false,false);
         //   newBook.Quote__c = book.Swap_Quote__c;
            newBook.Plot__c = book.Swap_Unit__c;
          //  newBook.Swapped_Booking__c = book.id;
            newBook.Swap_Unit_Status__c = '';
            newBook.Stage__c = 'Booked';
            newBook.Remark__c = 'Swapped from '+book.Name;
            newBookings.add(newBook);
        }
        
        List<Plot__c> updateplotList = new List<Plot__c>();
        List<Plot__c> bookplotList = [select id,name,Status__c from Plot__c where id in: Bookunits];
        List<Plot__c> availplotList = [select id,name,Status__c from Plot__c where id in: AvaiUnits];
        for(Plot__c plt : availplotList){
            plt.Status__c = 'Available';
            updateplotList.add(plt);
        }
        for(Plot__c plt1 : bookplotList){
            plt1.Status__c = 'Booked';
            updateplotList.add(plt1);
        }
        if(updateplotList.size() > 0){
            update updateplotList;
        }
        if(newBookings.size() > 0){
            insert newBookings;
        }
        Map<String,Id> paymentNumToId = new Map<String,Id>();
        List<Payment_schedule__c> mpsList = [select Id,Project__C,S_No__c,Master_Payment_Schedule__c,Name,Payment_Percent__c,Amount__c,Completed_Date__c,Payment_Due_Date__c,Status__c from payment_schedule__c where Booking__c  =:newBookings[0].Id ORDER BY S_No__c ASC];
        if(mpsList.size() > 0){
            system.debug('doing the things');
            for(Payment_schedule__c paySc : mpsList){
                paymentNumToId.put(paySc.Name,paySc.Id);
            }
        }
        Receipt__c rep;
        List<Receipt__c> recepAll = [select id,name,Booking__c,Receipt_Date__c from Receipt__c where Booking__c =: swappingBookings[0].Id and Approval_status__c = 'Approved'];
        if(recepAll.size() >0){
            if(recepAll.size() >0){
                Receipt__c rec = new Receipt__c();
                rec.Booking__c = newBookings[0].Id;
                rec.Approval_status__c = 'Approved';
                rec.Receipt_date__c = System.Today();
                insert rec;
            }
            rep = [select id,name,Booking__c from Receipt__c where Booking__c =: newBookings[0].Id limit 1];
        }
        List<Receipt_Line_Item__c> recLineList = [select id,name,Payment_Schedule__c,Payment_Schedule__r.Name,Booking__c,Amount__c,Received_Amount__c,Mode_of_Payment__c,Cheque_no_Transaction_Number__c from Receipt_Line_Item__c where Booking__c =: swappingBookings[0].Id and Receipt__r.Approval_status__c = 'Approved'];
        List<Receipt_Line_Item__c> repLineList = new List<Receipt_Line_Item__c>();
        if(recLineList.size() >0){
            if(rep != null){
                for(Receipt_Line_Item__c rltList: recLineList){
                    system.debug('adding line items');
                    Receipt_Line_Item__c rlt = rltList.clone(false, true, false, false);
                    rlt.Booking__c = newBookings[0].Id;
                    rlt.Receipt__c = rep.Id;
                    rlt.Payment_schedule__c = paymentNumToId.get(rltList.Payment_Schedule__r.Name);
                    system.debug(rlt);
                    repLineList.add(rlt);
                    system.debug('adding line items' + rlt);
                }
            }
            
            
        }
        if(repLineList.size()>0){
            insert repLineList;
            system.debug('inserted line itmes list' + repLineList.Size());
            system.debug('inserted line itmes list' + repLineList);
        }
        
    }
  */  
    
   
    @AuraEnabled
    public static Id saveFile(Id parentId, String fileName, String base64Data, String contentType) {
        system.debug(fileName);
        Attachment attach = new Attachment();
        system.debug(parentId);
        if(parentId != null){
            //  Quote__c quote = [select Id,Name,Leads__c from Quote__c where Id=:parentId];
            base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
            attach.parentId = parentId;
            attach.Body = EncodingUtil.base64Decode(base64Data);
            attach.Name = fileName; 
            attach.ContentType = contentType;
            Insert attach; 
            
        }
        system.debug('attach.Id'+attach.Id);
        return attach.Id; 
        
    }
    
    @auraEnabled
    public static string convertQuote(string recId,Booking__c book,List<Co_Applicant__c> applicantList){
        system.debug(applicantList);
       
        
        Quote__c qt = [SELECT Id,Name,SLead__c,Related_Source__c,SLead__r.Email,Approval_status__c,Quote_status__c,
                       Maintenance_Charge__c,Corpus_Fund__c,Built_up_area__c,Payment_Type__c,
                       Infrastructure_Charges_per_sqft__c,Project__c,Property_Type__c,Unit__c,
                       SLead__r.Secondary_Email__c,SLead__r.Name,Plot_Type__c,Plot_Land_Area__c,
                      /* GST1__c,Apartment_No__c,Token_Amount__c,Maintenance_Deposite__c,Other_Charges_Payable_on_Possession__c,Premium_Charge__c,BESCOM_Deposit_Rs__c,
                    Development_Charge__c,Block_Lookup__c,*/Quote_date__c,
                       Floor_Rise_Charges_Rate__c,Clubhouse_Charges__c,Unit__r.Status__c,Unit__r.Name,
                       Legal_Documentation_Charges__c FROM Quote__c WHERE Id=:recId];
        Project__c pro = [select id,name,CRM_executive__c from Project__c where Project__c =: qt.Project__c];
        //if(qt.Approval_status__c =='Approved'){
        if(qt.Unit__r.Status__c == 'Sold' || qt.Unit__r.Status__c == 'Booked'){
            return 'Unit not available';
        }
        else{
            
            Booking__c bk = new Booking__c();
            bk=book;
            bk.Quote__c = qt.Id;
            bk.SLead__c = qt.SLead__c;
             bk.Related_Source__c = qt.Related_Source__c;
            bk.Project__c = qt.Project__c;
            bk.Project1__c = pro.Id;
            bk.Plot__c = qt.Unit__c;
           // bk.CRM_Manager__c = pro.CRM_executive__c;
            //bk.Sales_Head__c = UserInfo.getUserId();
            
          //  bk.Block__c=qt.Block_Lookup__c;
           // bk.Plot_Land_Area__c=qt.Plot_Land_Area__c;
          //  bk.GST__c=qt.GST1__c;
           // bk.Apartment_Number__c=qt.Apartment_No__c;
           // bk.Payment_Type__c=qt.Payment_Type__c;
           // bk.Maintenance_Charge__c=qt.Maintenance_Charge__c;
           // bk.Legal_Documentation_Charges__c=qt.Legal_Documentation_Charges__c;
           // bk.Corpus_Fund__c=qt.Corpus_Fund__c;
            //bk.Email__c = qt.SLead__r.Email;
            bk.Email1__c=qt.SLead__r.Secondary_Email__c;
            //bk.Applicant_Mobile_Number__c =qt.Lead__r.Phone__c;
            bk.Applicant_Name__c = qt.SLead__r.Name;
            bk.Club_House__c= qt.Clubhouse_Charges__c;
            
          
            
            
         //   bk.Flat_no__c = qt.Unit__r.Name;
            insert bk;
            
            List<Co_Applicant__c> applicantListToInsert = new List<Co_Applicant__c>();
            for(Co_Applicant__c coA : applicantList){
                if(coA.Name != null && coA.Name != ''){
                    coA.Booking__c = bk.Id;
                    applicantListToInsert.add(coA);
                    
                }
                
            }
            insert applicantListToInsert;
            
            if( bk.Booking_Amount__c != null && bk.Booking_Amount__c != 0){
            //    ReceiptController.insertReceiptLineItems111(bk.Mode_Of_Payment__c, bk.Transaction_ID__c, string.valueof(bk.Booking_Date__c), bk.Id, bk.Booking_Amount__c);
            }
            
            Lead ld = new Lead();
            ld.Id=qt.SLead__c;
          //  ld.Unit_No__c=qt.Unit__c;
            ld.Lead_Status__c='Booked';
            ld.RecordTypeId=Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
            
            Quote__c quot = new Quote__c();
            quot.Id = qt.Id;
            quot.Quote_status__c = 'Converted';
            update quot;
            plot__c pt=new plot__c();
            System.debug('samp'+pt.Id);
            pt.id = qt.Unit__c;
            System.debug('samp2'+pt.Id);
            pt.Status__c='Booked';
            update pt;
            
            return bk.Id;
            
        }
        
    }
   /*
       public static void sendCustomNotification(Set<String> recepientIds, String Title, String Body, String recId, String notificationName){
        CustomNotificationType closedWonNotification = [SELECT Id,DeveloperName FROM CustomNotificationType WHERE DeveloperName =: notificationName LIMIT 1]; 
        Messaging.CustomNotification Notification = new Messaging.CustomNotification(); 
        Notification.setNotificationTypeId(closedWonNotification.id); 
        Notification.setSenderId(Userinfo.getUserId()); 
        Notification.setBody(Body); 
        Notification.setTitle(Title); 
        Notification.setTargetId(recId); 
        Notification.send(recepientIds);
    }
*/
}