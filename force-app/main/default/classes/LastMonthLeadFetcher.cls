public with sharing class LastMonthLeadFetcher {
    /**
     * Fetches leads created during the previous calendar month and logs the size.
     * @return List<Lead> leads from last month
     */
    public static List<Lead> fetchLastMonthLeads() {
        Date today = Date.today();
        Date firstDayThisMonth = Date.newInstance(today.year(), today.month(), 1);
        Date firstDayLastMonth = firstDayThisMonth.addMonths(-1);
        // Use start inclusive and end exclusive to cover full last month
        Datetime startDT = Datetime.newInstance(firstDayLastMonth.year(), firstDayLastMonth.month(), firstDayLastMonth.day(), 0, 0, 0);
        Datetime endDT = Datetime.newInstance(firstDayThisMonth.year(), firstDayThisMonth.month(), firstDayThisMonth.day(), 0, 0, 0);
  System.debug('Test---//');
      
        List<Lead> leads = [
            SELECT Id, Name, Company, Email, CreatedDate
            FROM Lead
            WHERE CreatedDate >= :startDT AND CreatedDate < :endDT
        ];

        System.debug(LoggingLevel.INFO, 'LastMonthLeadFetcher - leads.size: ' + leads.size());
        return leads;
    }
}
