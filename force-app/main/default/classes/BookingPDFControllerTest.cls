@isTest
public class BookingPDFControllerTest {
    
    @isTest
    public static void testbooking() {
         Lead testLead = new Lead(
            LastName='Test Lead',
            Allocated_Project__c='Zuari Garden City',
            Reassigned_By__c=UserInfo.getUserId(),
            Re_assigned_date__c = system.now(),
            Lead_status__c='New',
            Email='praveen@gmail.com',
            LeadSource ='Advertisement',
            Source_Type__c ='Digital Marketing',
            Phone__c='9898767998',
            Company='test'
        );
        insert testLead;

        Quote__c testQuote = new Quote__c(
            Project__c = 'Zuari Garden City',
            Payment_Type__c='Standard',
            Quote_status__c = 'Converted',
            SLead__c = testLead.Id
        );
        insert testQuote;
        Booking__C bk = New Booking__C();
        bk.SLead__c= testLead.id;
        bk.Quote__c= testQuote.id;
        insert bk;
         PageReference pref = Page.BookingForm; 
        BookingPDFController.sendEmailtoCustomer(bk.id);
        
        Test.setCurrentPage(pref);
        
        pref.getParameters().put('Id', String.valueOf(bk.Id));
        ApexPages.StandardController sc = new ApexPages.StandardController(bk);
        BookingPDFController testp = new BookingPDFController(sc);
       
       
    }

}