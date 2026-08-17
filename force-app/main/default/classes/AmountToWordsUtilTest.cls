@IsTest
public class AmountToWordsUtilTest {

    @IsTest
    static void testNullAmount() {
        String result = AmountToWordsUtil.convert(null);
        System.assertEquals('', result, 'Null amount should return empty string');
    }

    @IsTest
    static void testZeroAmount() {
        String result = AmountToWordsUtil.convert(0);
        System.assertEquals('AED Zero Only',result,'Zero amount conversion failed');
    }

    @IsTest
    static void testWholeNumberNoDecimals() {
        String result = AmountToWordsUtil.convert(125);
        System.assertEquals('AED One Hundred And Twenty Five Only', result, 'Whole number conversion failed');
    }

    @IsTest
    static void testAmountWithDecimals() {
        String result = AmountToWordsUtil.convert(125.50);
        System.assertEquals('AED One Hundred And Twenty Five and Fifty Fils Only', result,'Decimal conversion failed');
    }

    @IsTest
    static void testSingleDigitDecimal() {
        String result = AmountToWordsUtil.convert(10.05);
        System.assertEquals('AED Ten and Five Fils Only',result,'Single digit decimal conversion failed');
    }

    @IsTest
    static void testTensAndUnits() {
        System.assertEquals('AED Nineteen Only', AmountToWordsUtil.convert(19));

        System.assertEquals('AED Twenty One Only',AmountToWordsUtil.convert(21));
    }

    @IsTest
    static void testHundreds() {
        String result = AmountToWordsUtil.convert(999);
        System.assertEquals('AED Nine Hundred And Ninety Nine Only', result,'Hundreds conversion failed');
    }

    @IsTest
    static void testThousands() {
        String result = AmountToWordsUtil.convert(15432);
        System.assertEquals('AED Fifteen Thousand Four Hundred And Thirty Two Only',result,'Thousands conversion failed');
    }

    @IsTest
    static void testMillions() {
        String result = AmountToWordsUtil.convert(1200000);
        System.assertEquals('AED One Million Two Hundred Thousand Only',result,'Million conversion failed');
    }

    @IsTest
    static void testBillions() {
        String result = AmountToWordsUtil.convert(2000000001);
        System.assertEquals('AED Two Billion One Only',result,'Billion conversion failed');
    }

    @IsTest
    static void testDecimalRounding() {
        String result = AmountToWordsUtil.convert(10.999);
        System.assertEquals('AED Eleven Only', result,'Rounding to 2 decimals failed');
    }
}