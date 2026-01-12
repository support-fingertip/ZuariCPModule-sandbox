@isTest
public class BookingControllerTest {
    public static testmethod void samp1(){
       
 Project__c pjt = new Project__c();
        pjt.Name = 'Zuari Garden City';
        pjt.Project__c = 'Zuari Garden city';
        pjt.Active__c = true;
        insert pjt;
        
        Block__c bc = new Block__c();
        bc.Name='A';
        bc.Project__c=pjt.id;
        insert bc;
        
        Lead ld = new Lead();
        ld.LastName = 'Test';
        ld.Company = 'testcompany';
        ld.Phone__c = '8778987789';
        ld.Allocated_Project__c = 'Zuari Garden city';
        insert ld;
        
        
        
         plot__c ut = new Plot__c();
        ut.Name='Test plot';
        ut.Status__c='Available';
        ut.Project__c = pjt.Id;
        
        insert ut;
        
        Quote__c qc = new Quote__c();
        qc.Block_Lookup__c=bc.Id;
        qc.Quote_status__c = 'Converted';
        qc.Block__c = ' ';
        qc.Project__c = 'Zuari Garden city';
        qc.Payment_Type__c = 'Standard';
        qc.Sale_Area__c = 2567;
        qc.Built_up_area__c = 4567;
        qc.Rate_per_sqft__c = 7100;
        qc.Unit__c = ut.Id;
        insert qc;
       
       Master_payment_schedule__c mps = new Master_payment_schedule__c();
        mps.Project__c = pjt.id;
        mps.Name = 'test';
        mps.Payment_Percent__c = 20;
        mps.Status__c ='Completed';
        insert mps;
        
        Payment_schedule__c ps = new Payment_schedule__c();
         ps.Payment_percent__c =100;
        ps.Master_Payment_Schedule__c = mps.Id;
        ps.Is_Demanded__c = true;
        ps.Quote__c = qc.id;
         insert ps;
        List<Payment_schedule__c> PaymentList = new List<Payment_schedule__c>();
        PaymentList.add(ps);
        
        Booking__c book = new Booking__c();
        book.Funding_Type__c = 'Loan';
        book.Quote__c = qc.Id;
        book.Plot__c = ut.Id;
        book.CRM_Manager__c = UserInfo.getUserId();
        insert book;
        
        Booking__c book1 = new Booking__c();
        book1.Funding_Type__c = 'Loan';
        book1.Quote__c = qc.Id;
        book1.Plot__c = ut.Id;
        book1.CRM_Manager__c = UserInfo.getUserId();
        insert book1;
        
        Booking__c book2 = new Booking__c();
        book2.Funding_Type__c = 'Loan';
        book2.Quote__c = qc.Id;
        book2.Plot__c = ut.Id;
        book2.CRM_Manager__c = UserInfo.getUserId();
        insert book2;
        
        Booking__c book3 = new Booking__c();
        book3.Funding_Type__c = 'Loan';
        book3.Quote__c = qc.Id;
        book3.Plot__c = ut.Id;
        book3.CRM_Manager__c = UserInfo.getUserId();
        insert book3;

        
     /*   Receipt__c testReceipt = new Receipt__c(
            Approval_Status__c = 'Approved',
            Booking__c = book.id
        );
        insert testReceipt;*/

        // Create a test Receipt_Line_Item__c record linked to the Receipt and Additional_Charges
     /*   Receipt_Line_Item__c testLineItem = new Receipt_Line_Item__c(
            Receipt__c = testReceipt.Id,
            Payment_Schedule__c = ps.Id,
            Payment_Type__c = 'Additional Charges',
            Amount__c = 100,
            Received_Amount__c = 100,
            Booking__c = book.Id
        );
        insert testLineItem;*/

        // Create a test Co_Applicant__c record
        Co_Applicant__c testCoApplicant = new Co_Applicant__c(
            Name = 'Test Co-Applicant',
            Email__c = 'coapplicant@example.com',
            Booking__c = book.Id,
            Date_of_Birth__c = system.today() - 7300, 
            Nationality__c = 'NRI', 
            Occupation__c = 'Employee', 
            Son_Daughter_Wife_of__c = 'fhsgd'
        );
        //insert testCoApplicant;
        
        
        Payment_schedule__c ps1 = new Payment_schedule__c();
        ps1.Name = 'Additional Charges';
         ps1.Payment_percent__c =100;
        ps1.Master_Payment_Schedule__c = mps.Id;
        ps1.Is_Demanded__c = true;
         insert ps1;

        Map<Id,String> unitsToString = new Map<Id,String>();
        unitsToString.put(ut.Id,'Booked');
           PageReference pref = Page.BookingForm; 
        Test.setCurrentPage(pref);
        
        pref.getParameters().put('Id', String.valueOf(book.Id));
        ApexPages.StandardController sc = new ApexPages.StandardController(book);
        BookingPDFController testp = new BookingPDFController(sc);
      
        
        BookingPDFController.sendEmailtoCustomer(book.id);
        
        BookingController.getPaymentTypePicklistValues();
        BookingController.getFundingtTypePicklistValues();
        BookingController.quoteRecord(qc.Id);
        BookingController.changeUnitStatus(unitsToString);
        //BookingController.requestSaleAgreement(book.Id);
     //   BookingController.bookingCancellationApproval(book1.Id);
      //  BookingController.bookingSwappingApproval(book2.Id);
      
        BookingController.chnageUnitStatus(new List<Booking__c>{book});
        BookingController.convertQuote(qc.Id,new Booking__c(Funding_Type__c = 'Loan'),new List<Co_Applicant__c>{testCoApplicant});
       // BookingController.swapUnit(new List<Booking__c>{book3});
        //Test.stopTest();
        
        
        //List<String> paymentTypeValues = BookingController.getPaymentTypePicklistValues();
        //List<String> paymentfundingValues = BookingController.getFundingtTypePicklistValues();
        
        //BookingController.getQuote(testQuote.id);
        //test.stoptest();
        
    }
}