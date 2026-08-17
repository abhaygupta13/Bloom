public class AmountToWordsUtil {
	private static final List<String> units = new List<String>{
        '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six',
        'Seven', 'Eight', 'Nine', 'Ten', 'Eleven', 'Twelve',
        'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
        'Seventeen', 'Eighteen', 'Nineteen'
    };
    
    private static final List<String> tens = new List<String>{
        '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty',
        'Sixty', 'Seventy', 'Eighty', 'Ninety'
    };
        
    public static String convert(Decimal amount) {
        if (amount == null) return '';

        amount = amount.setScale(2);

        Long whole = amount.longValue();
        Integer decimalPart = Integer.valueOf(
            Math.round((amount - whole) * 100)
        );

        String words = 'AED ' + convertNumber(whole);

        if (decimalPart > 0) {
            words += ' and ' + convertNumber(decimalPart) + ' Fils';
        }

        return words + ' Only';
    }

    private static String convertNumber(Long number1) {

        if (number1 == 0) return 'Zero';

        if (number1 < 20) {
            return units[Integer.valueOf(number1)];
        }

        if (number1 < 100) {
            Long tensPart = number1 / 10;
            Long unitsPart = Math.mod(number1, 10);

            return tens[Integer.valueOf(tensPart)] +
                   (unitsPart > 0 ? ' ' + units[Integer.valueOf(unitsPart)] : '');
        }

        if (number1 < 1000) {
            Long remainder = Math.mod(number1, 100);
            return units[Integer.valueOf(number1 / 100)] + ' Hundred' +
                   (remainder > 0 ? ' And ' + convertNumber(remainder) : '');
        }

        if (number1 < 1000000) {
            Long remainder = Math.mod(number1, 1000);
            return convertNumber(number1 / 1000) + ' Thousand' +
                   (remainder > 0 ? ' ' + convertNumber(remainder) : '');
        }

        if (number1 < 1000000000) {
            Long remainder = Math.mod(number1, 1000000);
            return convertNumber(number1 / 1000000) + ' Million' +
                   (remainder > 0 ? ' ' + convertNumber(remainder) : '');
        }

        Long remainder = Math.mod(number1, 1000000000);
        return convertNumber(number1 / 1000000000) + ' Billion' +
               (remainder > 0 ? ' ' + convertNumber(remainder) : '');
    }
}