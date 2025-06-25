import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' hide Column, Row;
import '../utility/save_file_stub.dart' if (dart.library.html) '../utility/save_file_web.dart';

class AttendanceService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> fetchAttendanceData(int year, int month, List<int> validDates) async {
    List<Map<String, dynamic>> attendanceData = [];

    QuerySnapshot usersSnapshot = await firestore.collection('users').get();
    for (var userDoc in usersSnapshot.docs) {
      String userId = userDoc.id;

      QuerySnapshot profileSnapshot = await firestore.collection('users').doc(userId).collection('profile').get();

      String name = "", position = "";
      if (profileSnapshot.docs.isNotEmpty) {
        var profileDoc = profileSnapshot.docs.first;
        name = profileDoc['name'];
        position = profileDoc['position'];
      }

      Map<int, Map<String, dynamic>> attendance = {};
      QuerySnapshot attendanceSnapshot =
          await firestore.collection('users').doc(userId).collection('attendance').orderBy('uploadedAt').get();
      for (var doc in attendanceSnapshot.docs) {
        DateTime uploaded = (doc['uploadedAt'] as Timestamp).toDate();
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (uploaded.year == year && uploaded.month == month) {
          int day = uploaded.day;

          if (!attendance.containsKey(day)) {
            attendance[day] = {
              "status": "P",
              "late": data.containsKey("late") ? data["late"] : false,
            };
          }
        }
      }

      QuerySnapshot leaveSnapshot = await firestore.collection('users').doc(userId).collection('leave_requests').get();
      for (var leaveDoc in leaveSnapshot.docs) {
        DateTime start = (leaveDoc['startDate'] as Timestamp).toDate();
        DateTime end = (leaveDoc['endDate'] as Timestamp).toDate();
        String leaveType = leaveDoc['leaveType'];
        String status = leaveDoc['status'];

        if (status == "Approved") {
          DateTime current = start;
          while (!current.isAfter(end)) {
            if (current.year == year && current.month == month && validDates.contains(current.day)) {
              String status;
              if (leaveType == "Attendance Request") {
                status = "P";
              } else if (leaveType == "Sick Leave") {
                status = "S";
              } else {
                status = "T";
              }

              attendance[current.day] = {
                "status": status,
                "late": false,
              };
            }
            current = current.add(Duration(days: 1));
          }
        }
      }

      attendanceData.add({"name": name, "position": position, "attendance": attendance});
    }

    return attendanceData;
  }

  Future<List<DateTime>> fetchHolidays() async {
    DocumentSnapshot snapshot = await firestore.collection('admin').doc('holiday').get();

    List<dynamic> holidaysRaw = snapshot['holidays'] ?? [];
    List<DateTime> holidays = holidaysRaw.map((dateString) => DateTime.parse(dateString)).toList();

    return holidays;
  }

  Future<void> exportToExcel(
    String title,
    int year,
    int month,
    List<int> validDates,
    List<String> dayNames,
    List<Map<String, dynamic>> data,
    List<DateTime> holidays,
  ) async {
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];

    String getColumnLetter(int colIndex) {
      String columnName = "";
      while (colIndex > 0) {
        colIndex--;
        columnName = String.fromCharCode(65 + (colIndex % 26)) + columnName;
        colIndex = (colIndex / 26).floor();
      }
      return columnName;
    }

    final Style titleStyle = workbook.styles.add('TitleStyle')
      ..borders.all.lineStyle = LineStyle.thin
      ..hAlign = HAlignType.center
      ..vAlign = VAlignType.center
      ..bold = true
      ..fontSize = 20
      ..backColor = '#70AD47';

    final Style headerStyle = workbook.styles.add('HeaderStyle')
      ..borders.all.lineStyle = LineStyle.thin
      ..hAlign = HAlignType.center
      ..vAlign = VAlignType.center
      ..bold = true
      ..backColor = '#A9D08E';

    final Style subHeaderStyle = workbook.styles.add('SubHeaderStyle')
      ..borders.all.lineStyle = LineStyle.thin
      ..hAlign = HAlignType.center
      ..vAlign = VAlignType.center
      ..bold = true
      ..backColor = '#E2EFDA';

    final Style lateStyle = workbook.styles.add('LateStyle')
      ..borders.all.lineStyle = LineStyle.thin
      ..hAlign = HAlignType.center
      ..vAlign = VAlignType.center
      ..bold = true
      ..backColor = '#FF0000';

    sheet.getRangeByName('A1').columnWidth = 3.67;
    sheet.getRangeByName('B1:C1').columnWidth = 19.78;

    int totalColumns = 3 + validDates.length + 6;
    String lastColLetter = getColumnLetter(totalColumns);

    final Range reportTitleRange = sheet.getRangeByName('A1:${lastColLetter}1');
    reportTitleRange.merge();
    reportTitleRange.setText("LAPORAN ABSENSI KARYAWAN");
    reportTitleRange.cellStyle = titleStyle;
    sheet.getRangeByIndex(1, 1).rowHeight = 30.00;

    String monthName = DateFormat('MMMM').format(DateTime(year, month));
    sheet.getRangeByName('A2:C2').merge();
    sheet.getRangeByName('A2').setText('$monthName $year');
    sheet.getRangeByName('A2').cellStyle = headerStyle;
    sheet.getRangeByName('A2').cellStyle.fontSize = 14;
    sheet.getRangeByIndex(2, 1).rowHeight = 21.00;

    String lastDateCol = getColumnLetter(3 + validDates.length);
    sheet.getRangeByName('D2:${lastDateCol}2').merge();
    sheet.getRangeByName('D2').setText('Tanggal');
    sheet.getRangeByName('D2').cellStyle = headerStyle;
    sheet.getRangeByName('D2').cellStyle.fontSize = 14;

    String workDayColLetter = getColumnLetter(4 + validDates.length);
    sheet.getRangeByName('${workDayColLetter}2:${workDayColLetter}4').merge();
    sheet.getRangeByName('${workDayColLetter}2').setText("Jumlah Hari Kerja");
    sheet.getRangeByName('${workDayColLetter}2').cellStyle = headerStyle;
    sheet.getRangeByName('${workDayColLetter}2').cellStyle.wrapText = true;
    sheet.getRangeByName('${workDayColLetter}2').cellStyle.fontSize = 12;
    sheet.getRangeByName('${workDayColLetter}2').columnWidth = 12.33;

    String totalStartCol = getColumnLetter(5 + validDates.length);
    sheet.getRangeByName('${totalStartCol}2:${lastColLetter}3').merge();
    sheet.getRangeByName('${totalStartCol}2').setText('Total');
    sheet.getRangeByName('${totalStartCol}2').cellStyle = headerStyle;
    sheet.getRangeByName('${totalStartCol}2').cellStyle.fontSize = 14;

    sheet.getRangeByName('A3:A4').merge();
    sheet.getRangeByName('B3:B4').merge();
    sheet.getRangeByName('C3:C4').merge();

    sheet.getRangeByIndex(3, 1).setText("No.");
    sheet.getRangeByIndex(3, 2).setText("Name");
    sheet.getRangeByIndex(3, 3).setText("Position");

    int colIndex = 4;
    for (int i = 0; i < validDates.length; i++) {
      sheet.getRangeByIndex(3, colIndex).setText(validDates[i].toString());
      sheet.getRangeByIndex(4, colIndex).setText(dayNames[i]);
      sheet.getRangeByIndex(1, colIndex).columnWidth = 4.33;
      colIndex++;
    }

    sheet.getRangeByIndex(3, colIndex++).setText("Total");
    sheet.getRangeByIndex(4, colIndex++).setText("Present");
    sheet.getRangeByIndex(4, colIndex++).setText("Late");
    sheet.getRangeByIndex(4, colIndex++).setText("Sick");
    sheet.getRangeByIndex(4, colIndex++).setText("Time Off");
    sheet.getRangeByIndex(4, colIndex++).setText("Alpha");

    int presentColIndex = 4 + validDates.length + 1;
    for (int i = 0; i < 5; i++) {
      String colLetter = getColumnLetter(presentColIndex + i);
      sheet.getRangeByName('${colLetter}1').columnWidth = 7.67;
    }

    sheet.getRangeByName('A3:${lastDateCol}3').cellStyle = subHeaderStyle;
    sheet.getRangeByName('A4:${lastColLetter}4').cellStyle = subHeaderStyle;

    data.sort((a, b) => a["name"].compareTo(b["name"]));

    int rowIndex = 5;
    for (int i = 0; i < data.length; i++) {
      int col = 1;
      final attendance = data[i]["attendance"] as Map<int, dynamic>;
      int present = 0, absent = 0, timeOff = 0, late = 0, sick = 0;

      sheet.getRangeByIndex(rowIndex, col++).setText((i + 1).toString());
      sheet.getRangeByIndex(rowIndex, col++).setText(data[i]["name"]);
      sheet.getRangeByIndex(rowIndex, col++).setText(data[i]["position"]);

      for (int day in validDates) {
        final cell = sheet.getRangeByIndex(rowIndex, col);
        var statusData = attendance[day];
        DateTime date = DateTime(year, month, day);
        bool isSunday = date.weekday == DateTime.sunday;
        bool isHoliday = holidays.any((h) => h.year == date.year && h.month == date.month && h.day == date.day);

        if (statusData == null) {
          if (isSunday || isHoliday) {
            cell.setText("-");
          } else {
            cell.setText("A");
            absent++;
          }
        } else {
          String status = statusData["status"];
          bool isLate = statusData["late"] ?? false;

          if (status == "P") {
            present++;
            if (isLate) {
              late++;
              cell.setText("P");
              cell.cellStyle = lateStyle;
            } else {
              cell.setText("P");
            }
          } else if (status == "A") {
            cell.setText("A");
            absent++;
          } else if (status == "T") {
            if (!(isSunday || isHoliday)) {
              timeOff++;
              cell.setText("T");
            } else {
              cell.setText("-");
            }
          } else if (status == "S") {
            if (!(isSunday || isHoliday)) {
              sick++;
              cell.setText("S");
            } else {
              cell.setText("-");
            }
          }
        }
        col++;
      }

      int workDays = validDates.where((day) {
        final date = DateTime(year, month, day);
        return date.weekday != DateTime.sunday &&
            !holidays.any((h) => h.year == date.year && h.month == date.month && h.day == date.day);
      }).length;

      sheet.getRangeByIndex(rowIndex, col++).setText(workDays.toString());
      sheet.getRangeByIndex(rowIndex, col++).setText(present.toString());
      sheet.getRangeByIndex(rowIndex, col++).setText(late.toString());
      sheet.getRangeByIndex(rowIndex, col++).setText(sick.toString());
      sheet.getRangeByIndex(rowIndex, col++).setText(timeOff.toString());
      sheet.getRangeByIndex(rowIndex, col++).setText(absent.toString());

      rowIndex++;
    }

    for (int row = 1; row < rowIndex; row++) {
      for (int col = 1; col < colIndex; col++) {
        final Range cell = sheet.getRangeByIndex(row, col);
        cell.cellStyle.borders.all.lineStyle = LineStyle.thin;
        cell.cellStyle.hAlign = HAlignType.center;
        cell.cellStyle.vAlign = VAlignType.center;
      }
    }

    int newTableStartRow = rowIndex + 1;

    final Range newTableTitle = sheet.getRangeByIndex(newTableStartRow, 2);
    newTableTitle.setText("Name");
    newTableTitle.cellStyle = headerStyle;

    sheet.getRangeByIndex(newTableStartRow, 3).setText("Uang Harian");
    sheet.getRangeByIndex(newTableStartRow, 3).cellStyle = headerStyle;

    final Range dendaRange = sheet.getRangeByName("D$newTableStartRow:G$newTableStartRow");
    dendaRange.merge();
    dendaRange.setText("Denda");
    dendaRange.cellStyle = headerStyle;

    newTableStartRow++;

    final Style currencyStyle = workbook.styles.add('CurrencyStyle')
      ..borders.all.lineStyle = LineStyle.thin
      ..hAlign = HAlignType.center
      ..vAlign = VAlignType.center
      ..numberFormat = '_(Rp* #,##0.00';

    for (int i = 0; i < data.length; i++) {
      final row = newTableStartRow + i;
      final nameCell = sheet.getRangeByIndex(row, 2);
      nameCell.setText("${data[i]["name"]}");
      nameCell.cellStyle.hAlign = HAlignType.center;
      nameCell.cellStyle.vAlign = VAlignType.center;
      nameCell.cellStyle.borders.all.lineStyle = LineStyle.thin;

      final attendance = data[i]["attendance"] as Map<int, dynamic>;
      int uangHarian = 0;
      int dailyRate = 25000;

      for (var entry in attendance.entries) {
        int day = entry.key;
        String status = entry.value["status"];
        if (status == "P") {
          DateTime date = DateTime(year, month, day);
          bool isSunday = date.weekday == DateTime.sunday;
          bool isHoliday = holidays.any((h) => h.year == date.year && h.month == date.month && h.day == date.day);

          if (isSunday || isHoliday) {
            uangHarian += dailyRate * 2;
          } else {
            uangHarian += dailyRate;
          }
        }
      }

      final uangHarianCell = sheet.getRangeByIndex(row, 3);
      uangHarianCell.setNumber(uangHarian.toDouble());
      uangHarianCell.cellStyle = currencyStyle;

      int denda = 0;
      for (var entry in attendance.values) {
        if (entry["late"] == true) denda += 12500;
        if (entry["noDaily"] == true) denda += 25000;
      }

      final Range dendaRowRange = sheet.getRangeByName("D$row:G$row");
      dendaRowRange.merge();
      dendaRowRange.setNumber(denda.toDouble());
      dendaRowRange.cellStyle = currencyStyle;
    }

    final bytes = workbook.saveAsStream();
    workbook.dispose();

    String fileName = 'Attendance_Report_${monthName}_$year.xlsx';
    await saveAndLaunchFile(bytes, fileName);
  }
}
