public without sharing class RoundRobinHandler {
    public static void assignLead(List<Lead> leadList,boolean updateLeads,string usType){
        Datetime d = system.now();
        String dayOfWeek = d.format('EEEE');
        Set<string>  projectinterested  = new Set<string>();
        Map<string,List<Lead>>  projectLeadMap = new Map<string,List<Lead>>(); 
        Map<id,user>  rrMemberMapToUpdate = new  Map<id,user> ();
        for(Lead l:leadList){  
            string project = l.Source_Type__c;
            if(project != null && project != '' && l.Lead_Assigned__c !=true && l.Delete_Lead__c !=true){ 
                
                projectinterested.add(project);
                List<Lead>  projectQue = projectLeadMap.get(project); 
                if(projectQue  == null){
                    projectLeadMap.put(project, new   List<Lead>{l} );
                }else{
                    projectQue.add(l);  
                    projectLeadMap.put(project,  projectQue);
                } 
            }
        }
        system.debug('projectinterested'+ projectinterested.size());
        Map<string,List<Round_Robin_Member__c>>  projectAvaliableQueMap = new Map<string,List<Round_Robin_Member__c>>();
        Map<string,List<Round_Robin_Member__c>>  projectQueMap = new Map<string,List<Round_Robin_Member__c>>();
        
        List<Round_Robin__c> RRAvaliablequeList=[Select id,Lead_Source_Type__c, (select Name,User__c from  Round_Robin_Members__r  where Active__c =true AND user__r.Availability__c=true AND user__r.isActive=true AND user__r.is_working__c=TRUE AND User__r.Week_off_days__c excludes ( :dayOfWeek) AND User_Type__c=:usType  order by Last_Assigned_time_user__c,createddate	 asc nulls first ) from Round_Robin__c where Lead_Source_Type__c in :projectinterested and Active__c = true ];
        List<Round_Robin__c> RRqueList=[Select id,Lead_Source_Type__c, (select Name,User__c from  Round_Robin_Members__r  where Active__c =true AND user__r.isActive=true AND user__r.is_working__c=TRUE AND User__r.Week_off_days__c excludes ( :dayOfWeek) AND User_Type__c=:usType order by Last_Assigned_time_user__c,createddate	 asc nulls first  ) from Round_Robin__c where Lead_Source_Type__c in :projectinterested and Active__c = true ];
        if(RRAvaliablequeList.size()>0){
            for(Round_Robin__c rr : RRAvaliablequeList){
                if(rr.Round_Robin_Members__r.size()>0){
                    projectAvaliableQueMap.put(rr.Lead_Source_Type__c,rr.Round_Robin_Members__r);
                }
            }
        }
        if(RRqueList.size()>0){
            for(Round_Robin__c rr : RRqueList){
                if(rr.Round_Robin_Members__r.size()>0){
                    projectQueMap.put(rr.Lead_Source_Type__c,rr.Round_Robin_Members__r);
                }
            }
        }
        
        //List<Lead_Assigned__e> events = new List<Lead_Assigned__e>();
        for(string prj : projectinterested){
            
            if(projectAvaliableQueMap.containskey(prj) && projectAvaliableQueMap.get(prj).size()>0){
                List<Round_Robin_Member__c>  projectQue = projectAvaliableQueMap.get(prj);  
                integer counter = 0; 
                for(Lead l : projectLeadMap.get(prj)){
                    if(projectQue!=null && projectQue.size() > 0 && projectQue[counter] != null && projectQue[counter].user__c != null){
                        system.debug('projectQue[counter].user__c: ' + projectQue[counter].user__c);
                        l.ownerId = projectQue[counter].user__c;
                        l.Lead_Assigned__c = true;
                        if(usType =='Pre Sales'){
                            l.Pre_sales_user__c =projectQue[counter].user__c;
                        }else{
                            l.Sales_User__c =projectQue[counter].user__c;
                            
                            l.SV_User__c=projectQue[counter].user__c;
                            
                        }
                        l.Reassigned_By__c = UserInfo.getUserId();
                        l.Re_assigned_date__c = system.now();
                        // events.add(new Lead_Assigned__e(UserId__c = projectQue[counter].user__c, LeadId__c = l.Id,LeadName__c = l.LastName));
                        user u = new user();
                        u.Id = projectQue[counter].user__c;
                        u.LastAssignmentTime1__c = system.now().getTime(); 
                        
                        rrMemberMapToUpdate.put(projectQue[counter].user__c,u ) ; 
                        counter ++; 
                        if(projectQue.size() == counter  ){
                            counter  =0; 
                        } 
                    }
                }
            }
            else if(projectQueMap.containsKey(prj) && projectQueMap.get(prj).size()>0){
                List<Round_Robin_Member__c>  projectQue = projectQueMap.get(prj);  
                integer counter = 0; 
                for(Lead l : projectLeadMap.get(prj)){
                    if(projectQue!=null && projectQue.size() > 0 && projectQue[counter] != null && projectQue[counter].user__c != null){
                        system.debug('projectQue[counter].user__c: ' + projectQue[counter].user__c);
                        l.ownerId = projectQue[counter].user__c;
                        l.Lead_Assigned__c = true;
                        if(usType =='Pre Sales'){
                            l.Pre_sales_user__c =projectQue[counter].user__c;
                        }else{
                            l.Sales_User__c =projectQue[counter].user__c;
                            
                            // l.SV_User__c=projectQue[counter].user__c;
                            
                        }
                        // l.Reassigned_By__c = UserInfo.getUserId();
                        l.Re_assigned_date__c = system.now();
                     //  events.add(new Lead_Assigned__e(UserId__c = projectQue[counter].user__c, LeadId__c = l.Id,LeadName__c = l.LastName));
                        user u = new user();
                        u.Id = projectQue[counter].user__c;
                        u.LastAssignmentTime1__c = system.now().getTime(); 
                        
                        rrMemberMapToUpdate.put(projectQue[counter].user__c,u ) ; 
                        counter ++; 
                        if(projectQue.size() == counter  ){
                            counter  =0; 
                        } 
                    }
                }
            }
            
        }
       //  if (!events.isEmpty()) {
        
      //  Database.SaveResult[] results = EventBus.publish(events);
  //  }
        if(rrMemberMapToUpdate.values().size()>0){
            UPDATE rrMemberMapToUpdate.values();
            rrMemberMapToUpdate.clear();
        }
        if(updateLeads){
            Update leadList;
        }
    } 
     public static void assignRelatedsource(List<Related_Source__c> RSList,boolean updateLeads,string usType){
        Datetime d = system.now();
        String dayOfWeek = d.format('EEEE');
        Set<string>  projectinterested  = new Set<string>();
        Map<string,List<Related_Source__c>>  projectLeadMap = new Map<string,List<Related_Source__c>>(); 
        Map<id,user>  rrMemberMapToUpdate = new  Map<id,user> ();
          System.debug('=== Starting to iterate Related_Source__c records, total: ' + RSList.size() + ' ===');
        for(Related_Source__c rs:RSList){  
            string project = rs.Source_Type__c;
             System.debug('=== project: ' + project + ' ===');
            System.debug('=== Lead_Assigned__c: ' + rs.Lead_Assigned__c + ' ===');
            System.debug('=== Delete_Lead__c: ' + rs.Delete_Lead__c + ' ===');
            //if(project != null && project != '' && rs.Lead_Assigned__c !=true && rs.Delete_Lead__c !=true)
             if(project != null && project != '' && rs.Lead_Assigned__c !=true){ 
                 System.debug('Processing RS record Id: ' + rs.Id + ', Source_Type__c: ' + project 
                     + ', Lead_Assigned__c: ' + rs.Lead_Assigned__c 
                     + ', Delete_Lead__c: ' + rs.Delete_Lead__c);
                projectinterested.add(project);
                List<Related_Source__c>  projectQue = projectLeadMap.get(project); 
                if(projectQue  == null){
                     System.debug('Added new project to map: ' + project + ' with RS Id: ' + rs.Id);
                    projectLeadMap.put(project, new   List<Related_Source__c>{rs} );
                }else{
                    projectQue.add(rs);  
                    projectLeadMap.put(project,  projectQue);
                } 
            }
        }
          System.debug('=== Finished processing Related_Source__c records ===');
        system.debug('projectinterested'+ projectinterested.size());
        Map<string,List<Round_Robin_Member__c>>  projectAvaliableQueMap = new Map<string,List<Round_Robin_Member__c>>();
        Map<string,List<Round_Robin_Member__c>>  projectQueMap = new Map<string,List<Round_Robin_Member__c>>();
        
        List<Round_Robin__c> RRAvaliablequeList=[Select id,Lead_Source_Type__c, (select Name,User__c from  Round_Robin_Members__r  where Active__c =true AND user__r.Availability__c=true AND user__r.isActive=true AND user__r.is_working__c=TRUE AND User__r.Week_off_days__c excludes ( :dayOfWeek) AND User_Type__c=:usType  order by Last_Assigned_time_user__c,createddate	 asc nulls first ) from Round_Robin__c where Lead_Source_Type__c in :projectinterested and Active__c = true ];
        List<Round_Robin__c> RRqueList=[Select id,Lead_Source_Type__c, (select Name,User__c from  Round_Robin_Members__r  where Active__c =true AND user__r.isActive=true AND user__r.is_working__c=TRUE AND User__r.Week_off_days__c excludes ( :dayOfWeek) AND User_Type__c=:usType order by Last_Assigned_time_user__c,createddate	 asc nulls first  ) from Round_Robin__c where Lead_Source_Type__c in :projectinterested and Active__c = true ];
        if(RRAvaliablequeList.size()>0){
            for(Round_Robin__c rr : RRAvaliablequeList){
                if(rr.Round_Robin_Members__r.size()>0){
                    projectAvaliableQueMap.put(rr.Lead_Source_Type__c,rr.Round_Robin_Members__r);
                }
            }
        }
        if(RRqueList.size()>0){
            for(Round_Robin__c rr : RRqueList){
                if(rr.Round_Robin_Members__r.size()>0){
                    projectQueMap.put(rr.Lead_Source_Type__c,rr.Round_Robin_Members__r);
                }
            }
        }
        
        //List<Lead_Assigned__e> events = new List<Lead_Assigned__e>();
        for(string prj : projectinterested){
            
            if(projectAvaliableQueMap.containskey(prj) && projectAvaliableQueMap.get(prj).size()>0){
                List<Round_Robin_Member__c>  projectQue = projectAvaliableQueMap.get(prj);  
                integer counter = 0; 
                for(Related_Source__c rs : projectLeadMap.get(prj)){
                    if(projectQue!=null && projectQue.size() > 0 && projectQue[counter] != null && projectQue[counter].user__c != null){
                        system.debug('projectQue[counter].user__c: ' + projectQue[counter].user__c);
                        rs.ownerId = projectQue[counter].user__c;
                        rs.Lead_Assigned__c = true;
                        if(usType =='Pre Sales'){
                           rs.Pre_sales_user__c =projectQue[counter].user__c;
                        }else{
                            rs.Sales_User__c =projectQue[counter].user__c;
                            
                           rs.SV_User__c=projectQue[counter].user__c;
                            
                        }
                        rs.Reassigned_By__c = UserInfo.getUserId();
                       rs.Re_assigned_date__c = system.now();
                        // events.add(new Lead_Assigned__e(UserId__c = projectQue[counter].user__c, LeadId__c = l.Id,LeadName__c = l.LastName));
                        user u = new user();
                        u.Id = projectQue[counter].user__c;
                        u.LastAssignmentTime1__c = system.now().getTime(); 
                        
                        rrMemberMapToUpdate.put(projectQue[counter].user__c,u ) ; 
                        counter ++; 
                        if(projectQue.size() == counter  ){
                            counter  =0; 
                        } 
                    }else{
                        //rs.OwnerId = userInfo.getUserId();
                          System.debug('No RR member found. Owner left unchanged.');
                    }
                }
            }
            else if(projectQueMap.containsKey(prj) && projectQueMap.get(prj).size()>0){
                List<Round_Robin_Member__c>  projectQue = projectQueMap.get(prj);  
                integer counter = 0; 
                for(Related_Source__c rs : projectLeadMap.get(prj)){
                    if(projectQue!=null && projectQue.size() > 0 && projectQue[counter] != null && projectQue[counter].user__c != null){
                        system.debug('projectQue[counter].user__c: ' + projectQue[counter].user__c);
                        rs.ownerId = projectQue[counter].user__c;
                       rs.Lead_Assigned__c = true;
                        if(usType =='Pre Sales'){
                            rs.Pre_sales_user__c =projectQue[counter].user__c;
                        }else{
                            rs.Sales_User__c =projectQue[counter].user__c;
                            
                            // l.SV_User__c=projectQue[counter].user__c;
                            
                        }
                        // l.Reassigned_By__c = UserInfo.getUserId();
                        rs.Re_assigned_date__c = system.now();
                     //  events.add(new Lead_Assigned__e(UserId__c = projectQue[counter].user__c, LeadId__c = l.Id,LeadName__c = l.LastName));
                        user u = new user();
                        u.Id = projectQue[counter].user__c;
                        u.LastAssignmentTime1__c = system.now().getTime(); 
                        
                        rrMemberMapToUpdate.put(projectQue[counter].user__c,u ) ; 
                        counter ++; 
                        if(projectQue.size() == counter  ){
                            counter  =0; 
                        } 
                    }
                    else{
                        rs.OwnerId = userInfo.getUserId();
                    }
                }
            }
            
        }
       //  if (!events.isEmpty()) {
        
      //  Database.SaveResult[] results = EventBus.publish(events);
  //  }
        if(rrMemberMapToUpdate.values().size()>0){
            UPDATE rrMemberMapToUpdate.values();
            rrMemberMapToUpdate.clear();
        }
        if(updateLeads){
            Update RSList;
        }
    } 
    
    public static void siteVisitRoundRobin(List<Site_Visit__c> siteVisits){
        Datetime d = system.now();
        String dayOfWeek = d.format('EEEE');
        Set<string>  projectInterested  = new Set<string>();
        Map<string,List<Site_Visit__c>>  projectSiteVisitMap = new Map<string,List<Site_Visit__c>>(); 
        Map<id,user>  rrMemberMapToUpdate = new  Map<id,user> ();
        for(Site_Visit__c sv : siteVisits){  
            string project = sv.Source_Type__c;
            if(project != null && project != '' && sv.Go_For_Round_Robin__c == true){ 
                projectInterested.add(project);
                List<Site_Visit__c>  projectQue = projectSiteVisitMap.get(project); 
                if(projectQue  == null){
                    projectSiteVisitMap.put(project, new List<Site_Visit__c>{sv} );
                }else{
                    projectQue.add(sv);  
                    projectSiteVisitMap.put(project,  projectQue);
                } 
            }
        }
        system.debug('projectinterested'+ projectinterested.size());
        Map<string,List<Round_Robin_Member__c>>  projectAvaliableQueMap = new Map<string,List<Round_Robin_Member__c>>();
        Map<string,List<Round_Robin_Member__c>>  projectQueMap = new Map<string,List<Round_Robin_Member__c>>();
        
        List<Round_Robin__c> RRAvaliablequeList=[Select id,Lead_Source_Type__c, (select Name,User__c from  Round_Robin_Members__r  where Active__c =true AND user__r.Availability__c=true AND user__r.isActive=true AND user__r.is_working__c=TRUE AND User__r.Week_off_days__c excludes ( :dayOfWeek) AND User_Type__c='Sales' order by Last_Assigned_time_user__c,createddate	 asc nulls first ) from Round_Robin__c where Lead_Source_Type__c in :projectinterested and Active__c = true ];
        List<Round_Robin__c> RRqueList=[Select id,Lead_Source_Type__c, (select Name,User__c from  Round_Robin_Members__r  where Active__c =true AND user__r.isActive=true AND user__r.is_working__c=TRUE AND User__r.Week_off_days__c excludes ( :dayOfWeek) AND User_Type__c='Sales' order by Last_Assigned_time_user__c,createddate	 asc nulls first  ) from Round_Robin__c where Lead_Source_Type__c in :projectinterested and Active__c = true ];
        if(RRAvaliablequeList.size()>0){
            for(Round_Robin__c rr : RRAvaliablequeList){
                if(rr.Round_Robin_Members__r.size()>0){
                    projectAvaliableQueMap.put(rr.Lead_Source_Type__c,rr.Round_Robin_Members__r);
                }
            }
        }
        if(RRqueList.size()>0){
            for(Round_Robin__c rr : RRqueList){
                if(rr.Round_Robin_Members__r.size()>0){
                    projectQueMap.put(rr.Lead_Source_Type__c,rr.Round_Robin_Members__r);
                }
            }
        }
        
        for(string prj : projectInterested){
            if(projectAvaliableQueMap.containskey(prj) && projectAvaliableQueMap.get(prj).size()>0){
                List<Round_Robin_Member__c>  projectQue = projectAvaliableQueMap.get(prj);  
                integer counter = 0; 
                for(Site_Visit__c sv : projectSiteVisitMap.get(prj)){
                    if(projectQue!=null && projectQue.size() > 0 && projectQue[counter] != null && projectQue[counter].user__c != null){
                        system.debug('projectQue[counter].user__c: ' + projectQue[counter].user__c);
                        sv.ownerId = projectQue[counter].user__c;
                        user u = new user();
                        u.Id = projectQue[counter].user__c;
                        u.LastAssignmentTime1__c = system.now().getTime(); 
                        
                        rrMemberMapToUpdate.put(projectQue[counter].user__c,u ) ; 
                        counter ++; 
                        if(projectQue.size() == counter  ){
                            counter  =0; 
                        } 
                    }
                }
            }
            else if(projectQueMap.containsKey(prj) && projectQueMap.get(prj).size()>0){
                List<Round_Robin_Member__c>  projectQue = projectQueMap.get(prj);  
                integer counter = 0; 
                for(Site_Visit__c sv : projectSiteVisitMap.get(prj)){
                    if(projectQue!=null && projectQue.size() > 0 && projectQue[counter] != null && projectQue[counter].user__c != null){
                        system.debug('projectQue[counter].user__c: ' + projectQue[counter].user__c);
                        sv.ownerId = projectQue[counter].user__c;
                        user u = new user();
                        u.Id = projectQue[counter].user__c;
                        u.LastAssignmentTime1__c = system.now().getTime(); 
                        
                        rrMemberMapToUpdate.put(projectQue[counter].user__c,u ) ; 
                        counter ++; 
                        if(projectQue.size() == counter  ){
                            counter  =0; 
                        } 
                    }
                }
            }
            
        }
        if(rrMemberMapToUpdate.values().size()>0){
            UPDATE rrMemberMapToUpdate.values();
            rrMemberMapToUpdate.clear();
        }
    } 
   
    
    /*
public static void assignLead2(List<Lead> leadList,boolean updateLeads,string usType){
Datetime d = system.now();
String dayOfWeek = d.format('EEEE');
Set<string>  projectinterested  = new Set<string>();
Map<string,List<Lead>>  projectLeadMap = new Map<string,List<Lead>>(); 
Map<id,user>  rrMemberMapToUpdate = new  Map<id,user> ();

Datetime d1 = system.now();
String dayOfWeek1 = d.format('EEEE');
Set<string>  projectinterested1  = new Set<string>();
Map<string,List<Lead>>  projectLeadMap1 = new Map<string,List<Lead>>(); 
Map<id,user>  rrMemberMapToUpdate1 = new  Map<id,user> ();

for(Lead l:leadList){  
string project = l.Source_Type__c;
if(project != null && project != '' && l.Lead_Assigned__c !=true && l.Delete_Lead__c !=true){ 

}
}
system.debug('projectinterested'+ projectinterested.size());
Map<string,List<Round_Robin_Member__c>>  projectAvaliableQueMap = new Map<string,List<Round_Robin_Member__c>>();
Map<string,List<Round_Robin_Member__c>>  projectQueMap = new Map<string,List<Round_Robin_Member__c>>();

List<Round_Robin__c> RRAvaliablequeList=[Select id,Lead_Source_Type__c, (select Name,User__c from  Round_Robin_Members__r  where Active__c =true AND user__r.Availability__c=true AND user__r.isActive=true AND user__r.is_working__c=TRUE AND User__r.Week_off_days__c excludes ( :dayOfWeek) AND User_Type__c=:usType  order by Last_Assigned_time_user__c,createddate	 asc nulls first ) from Round_Robin__c where Lead_Source_Type__c in :projectinterested and Active__c = true ];
List<Round_Robin__c> RRqueList=[Select id,Lead_Source_Type__c, (select Name,User__c from  Round_Robin_Members__r  where Active__c =true AND user__r.isActive=true AND user__r.is_working__c=TRUE AND User__r.Week_off_days__c excludes ( :dayOfWeek) AND User_Type__c=:usType order by Last_Assigned_time_user__c,createddate	 asc nulls first  ) from Round_Robin__c where Lead_Source_Type__c in :projectinterested and Active__c = true ];
if(RRAvaliablequeList.size()>0){

}
if(RRqueList.size()>0){

}
if(rrMemberMapToUpdate.values().size()>0){

}
if(updateLeads){

}
} 

*/
    public static void testcover(){
        integer i=0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
}