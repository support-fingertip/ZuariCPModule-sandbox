public with sharing class ENUMRequestHelper {
    // small wrapper to deserialize the validFor property from PicklistEntry JSON
    public class PicklistInfo {
        public String validFor;
    }

    /**
     * Generic helper - returns map: controllingValue -> list of dependent values
     * Uses JSON serialize/deserialize to access PicklistEntry.validFor and decode it.
     */
    public static Map<String, List<String>> getFieldDependencyMap( String objectApiName, String controllingFieldApiName,String dependentFieldApiName ) {
        Map<String, List<String>> controllingInfo = new Map<String, List<String>>();

        Schema.SObjectType sType = Schema.getGlobalDescribe().get(objectApiName);
        if (sType == null) return controllingInfo;

        Schema.DescribeSObjectResult describeResult = sType.getDescribe();
        Map<String, Schema.SObjectField> fm = describeResult.fields.getMap();

        if (!fm.containsKey(controllingFieldApiName) || !fm.containsKey(dependentFieldApiName)) {
            return controllingInfo;
        }

        Schema.DescribeFieldResult controllingFieldInfo = fm.get(controllingFieldApiName).getDescribe();
        Schema.DescribeFieldResult dependentFieldInfo  = fm.get(dependentFieldApiName).getDescribe();

        List<Schema.PicklistEntry> controllingValues = controllingFieldInfo.getPicklistValues();
        List<Schema.PicklistEntry> dependentValues  = dependentFieldInfo.getPicklistValues();

        // initialize keys (use API value as key)
        for (Schema.PicklistEntry cv : controllingValues) {
            controllingInfo.put(cv.getValue(), new List<String>());
        }

        // deserialize dependent picklist entries to get validFor
        List<PicklistInfo> depInfos = (List<PicklistInfo>) JSON.deserialize(
            JSON.serialize(dependentValues),
            List<PicklistInfo>.class
        );

        for (Integer i = 0; i < dependentValues.size(); i++) {
            Schema.PicklistEntry dep = dependentValues[i];
            PicklistInfo info = depInfos[i];

            if (String.isBlank(info.validFor)) continue;

            // convert base64 -> hex string
            String hexString = EncodingUtil.convertToHex(EncodingUtil.base64Decode(info.validFor)).toUpperCase();

            Integer baseCount = 0;
            // each hex char represents 4 bits: check each nibble's bits
            for (Integer curr : hexString.getChars()) {
                Integer val = 0;
                if (curr >= 65) { // 'A'..'F'
                    val = curr - 65 + 10;
                } else { // '0'..'9'
                    val = curr - 48;
                }

                // map the 4 bits to up to 4 controlling values (respect array bounds)
                if ((val & 8) == 8 && baseCount + 0 < controllingValues.size()) {
                    String key = controllingValues[baseCount + 0].getValue();
                    if (!controllingInfo.get(key).contains(dep.getValue())) controllingInfo.get(key).add(dep.getValue());
                }
                if ((val & 4) == 4 && baseCount + 1 < controllingValues.size()) {
                    String key = controllingValues[baseCount + 1].getValue();
                    if (!controllingInfo.get(key).contains(dep.getValue())) controllingInfo.get(key).add(dep.getValue());
                }
                if ((val & 2) == 2 && baseCount + 2 < controllingValues.size()) {
                    String key = controllingValues[baseCount + 2].getValue();
                    if (!controllingInfo.get(key).contains(dep.getValue())) controllingInfo.get(key).add(dep.getValue());
                }
                if ((val & 1) == 1 && baseCount + 3 < controllingValues.size()) {
                    String key = controllingValues[baseCount + 3].getValue();
                    if (!controllingInfo.get(key).contains(dep.getValue())) controllingInfo.get(key).add(dep.getValue());
                }

                baseCount += 4;
            }
        }

        return controllingInfo;
    }

    // Convenience method for your Support_Request__c fields
    public static Map<String, List<String>> getSupportRequestDependentMap() {
        return getFieldDependencyMap('Support_Request__c', 'Support_Type__c', 'ConcernList__c');
    }

    public static List<String> getProjectConcerns() {
        Map<String,List<String>> m = getSupportRequestDependentMap();
        return m.containsKey('Projects') ? m.get('Projects') : new List<String>();
    }
    public static List<String> getSalesConcerns() {
        Map<String,List<String>> m = getSupportRequestDependentMap();
        return m.containsKey('Sales') ? m.get('Sales') : new List<String>();
    }

    // @AuraEnabled wrapper for LWC / Aura (cacheable to allow @wire in LWC)
    @AuraEnabled(cacheable=true)
    public static Map<String, List<String>> fetchSupportRequestPicklistMap() {
        return getSupportRequestDependentMap();
    }
}