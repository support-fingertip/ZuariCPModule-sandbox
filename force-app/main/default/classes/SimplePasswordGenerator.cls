public class SimplePasswordGenerator {
    
    public static String generatePassword() {
        String letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
        String numbers = '0123456789';
        
        String letterPart = '';
        for (Integer i = 0; i < 3; i++) {
            Integer randomIndex = getRandomNumber(letters.length());
            letterPart += letters.substring(randomIndex, randomIndex + 1);
        }
        
        String numberPart = '';
        for (Integer i = 0; i < 3; i++) {
            Integer randomIndex = getRandomNumber(numbers.length());
            numberPart += numbers.substring(randomIndex, randomIndex + 1);
        }
        
        return letterPart + numberPart;
    }
   
    private static Integer getRandomNumber(Integer maxValue) {
        Long seed = DateTime.now().getTime();
        
        return Math.mod(Math.abs(seed.intValue()), maxValue);
    }
}