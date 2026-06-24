// returns today's date as dd mm yyyy (28/06/2026)
String todaysDateDDMMYYYY() {

  var dateTimeObject = DateTime.now();

// year
  String year = dateTimeObject.year.toString();

// month
  String month = dateTimeObject.month.toString();
  if (month.length == 1) {
    month = '0$month';
  }

// day
  String day = dateTimeObject.day.toString();
  if (day.length == 1) {
    day = '0$day';
  }

// final format dd mm yyyy
  String ddmmyyyy = '$day/$month/$year';

  return ddmmyyyy;


}

// conert string dd mm yyyy to datetime object
DateTime createDateTimeObject(String ddmmyyyy) {
  int dd = int.parse(ddmmyyyy.substring(0, 2));
  int mm = int.parse(ddmmyyyy.substring(3, 5));
  int yyyy = int.parse(ddmmyyyy.substring(6, 10));

  DateTime dateTimeObject = DateTime(yyyy, mm, dd);
  return dateTimeObject;
}

// convert datetime object to dd mm yyyy string
String convertDateTimeObjectToDDMMYYYY(DateTime dateTimeObject) {
  String year = dateTimeObject.year.toString();

  String month = dateTimeObject.month.toString();
  if (month.length == 1) {
    month = '0$month';
  }

  String day = dateTimeObject.day.toString();
  if (day.length == 1) {
    day = '0$day';
  }

  String ddmmyyyy = '$day/$month/$year';

  return ddmmyyyy;
}