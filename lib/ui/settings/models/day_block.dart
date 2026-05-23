import '../../../data/models/exam_schedule_slot.dart';

class DayBlock {
  DateTime? date;
  final List<ExamScheduleSlot> periods;
  bool isExpanded = true;

  DayBlock({this.date, List<ExamScheduleSlot>? periods})
      : periods = periods ?? [DayBlock.defaultSlot()];

  static ExamScheduleSlot defaultSlot() =>
      ExamScheduleSlot(date: null, startHour: 8, endHour: 13, studentsPerHour: 4);
}
