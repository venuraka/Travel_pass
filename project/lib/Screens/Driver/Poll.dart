import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../Components/AppBar.dart';
import '../Components/CustomSnackBar.dart';
import 'PassengerSummery.dart';
import '../../services/Database.dart';
import '../../models/PollModel.dart';
import '../../models/DriverModel.dart';
import '../../services/NotificationService.dart';



class PollScreen extends StatefulWidget {
  const PollScreen({super.key});

  @override
  State<PollScreen> createState() => _PollScreenState();
}

class _PollScreenState extends State<PollScreen> {
  // UI state: all dates currently shown as "selected" on the calendar.
  // Initially loaded from DB, then the user can toggle dates on/off.
  final Set<DateTime> _uiSelectedDates = {};

  // Snapshot of what is currently saved in DB (loaded on init).
  // Used to calculate the diff when saving.
  final Set<DateTime> _dbSavedDates = {};

  // Maps each saved date to its Firestore document ID
  final Map<DateTime, String> _dateToDocId = {};

  // Maps each document ID to its list of dates (for partial updates)
  final Map<String, List<DateTime>> _docIdToDates = {};

  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DriverModel? _currentDriver;
  final PushNotificationService _notificationService = PushNotificationService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchDriverAndPolls();
  }

  Future<void> _fetchDriverAndPolls() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final driver = await _dbService.getDriverData(user.uid);
        _currentDriver = driver;

        if (driver != null) {
          final polls = await _dbService.getPollsByDriver(driver.uid);
          setState(() {
            _uiSelectedDates.clear();
            _dbSavedDates.clear();
            _dateToDocId.clear();
            _docIdToDates.clear();

            for (var poll in polls) {
              final normalizedDates = <DateTime>[];
              for (var date in poll.activeDates) {
                final normalized = DateTime.utc(
                  date.year,
                  date.month,
                  date.day,
                );
                _uiSelectedDates.add(normalized);
                _dbSavedDates.add(normalized);
                _dateToDocId[normalized] = poll.id;
                normalizedDates.add(normalized);
              }
              _docIdToDates[poll.id] = normalizedDates;
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, "Error loading data: $e");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onDaySelected(DateTime day, DateTime focusedDay) {
    final normalizedDay = DateTime.utc(day.year, day.month, day.day);
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);

    if (normalizedDay.isBefore(today)) {
      CustomSnackBar.showError(context, "Cannot select past dates.");
      return;
    }

    setState(() {
      // Simple toggle: tap to select, tap again to deselect
      if (_uiSelectedDates.contains(normalizedDay)) {
        _uiSelectedDates.remove(normalizedDay);
      } else {
        _uiSelectedDates.add(normalizedDay);
      }
    });
  }

  Future<void> _saveDates() async {
    if (_currentDriver == null) {
      CustomSnackBar.showError(context, "Driver details not found.");
      return;
    }

    // Calculate diffs
    // Additions: dates in UI but NOT in DB
    final datesToAdd = _uiSelectedDates.difference(_dbSavedDates).toList();
    // Removals: dates in DB but NOT in UI (user deselected them)
    final datesToRemove = _dbSavedDates.difference(_uiSelectedDates).toList();

    if (datesToAdd.isEmpty && datesToRemove.isEmpty) {
      CustomSnackBar.showError(context, "No changes to save.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uuid = const Uuid();

      // --- Handle Additions: create ONE new document with all new dates ---
      if (datesToAdd.isNotEmpty) {
        final newPoll = PollModel(
          id: uuid.v4(),
          driverId: _currentDriver!.uid,
          vehiclePlate: _currentDriver!.vehiclePlate,
          activeDates: datesToAdd,
          createdAt: Timestamp.now(),
        );
        await _dbService.createPoll(newPoll);

        // Trigger Push Notification for new poll
        await _notificationService.sendPushNotification(
          driverId: _currentDriver!.uid,
          title: "New Poll Started",
          body: "Your driver has started a new attendance poll. Please mark your attendance.",
          data: {"type": "poll", "driverId": _currentDriver!.uid},
        );
      }


      // --- Handle Removals: remove dates from their respective documents ---
      if (datesToRemove.isNotEmpty) {
        // Group dates-to-remove by their document ID
        final Map<String, List<DateTime>> removalsByDoc = {};
        for (var date in datesToRemove) {
          final docId = _dateToDocId[date];
          if (docId != null) {
            removalsByDoc.putIfAbsent(docId, () => []).add(date);
          }
        }

        for (var entry in removalsByDoc.entries) {
          final docId = entry.key;
          final removingDates = entry.value;
          final currentDates = _docIdToDates[docId] ?? [];

          // Calculate remaining dates for this document
          final remainingDates = currentDates
              .where((d) => !removingDates.contains(d))
              .toList();

          if (remainingDates.isEmpty) {
            // All dates removed → delete the entire document
            await _dbService.deletePoll(docId);
          } else {
            // Some dates remain → update the document
            await _dbService.updatePollDates(docId, remainingDates);
          }
        }
      }

      // Refresh from DB to sync state
      await _fetchDriverAndPolls();

      if (mounted) {
        CustomSnackBar.showSuccess(context, "Poll updated successfully!");
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, "Error saving polls: $e");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F5),
      appBar: const CustomAppBar(title: 'Start a Poll'),
      body: _isLoading && _currentDriver == null
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF05A664)),
            )
          : Column(
              children: [
                // Calendar takes remaining space
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 30.0,
                      left: 16.0,
                      right: 16.0,
                    ),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: DateTime.now(),
                      calendarFormat: CalendarFormat.month,

                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(
                          color: Color(0xFF121415),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        headerMargin: EdgeInsets.only(bottom: 30.0),
                      ),

                      // We handle all styling via calendarBuilders
                      // so we disable the default selectedDayPredicate
                      selectedDayPredicate: (day) => false,

                      onDaySelected: _onDaySelected,

                      onDayLongPressed: (selectedDay, focusedDay) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PassengersummeryScreen(
                              selectedDay: selectedDay,
                            ),
                          ),
                        );
                      },

                      // --- Custom builders for 3 date states ---
                      calendarBuilders: CalendarBuilders(
                        // Today always gets special treatment
                        todayBuilder: (context, day, focusedDay) {
                          final normalized = DateTime.utc(
                            day.year,
                            day.month,
                            day.day,
                          );
                          final isSelected = _uiSelectedDates.contains(
                            normalized,
                          );
                          final isSaved = _dbSavedDates.contains(normalized);

                          Color bgColor;
                          if (isSelected && isSaved) {
                            bgColor = const Color(
                              0xFF047857,
                            ); // Saved: dark emerald
                          } else if (isSelected && !isSaved) {
                            bgColor = const Color(
                              0xFF05A664,
                            ); // New: bright green
                          } else {
                            bgColor = const Color(
                              0xFF121415,
                            ); // Today default: dark
                          }

                          return Container(
                            margin: const EdgeInsets.all(4.0),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: bgColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(
                                        0xFF047857,
                                      ) // Dark green border when selected
                                    : const Color(
                                        0xFF05A664,
                                      ), // Bright green border default
                                width: 2.5,
                              ),
                            ),
                            child: Text(
                              '${day.day}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          );
                        },

                        // Default (non-today) days
                        defaultBuilder: (context, day, focusedDay) {
                          final normalized = DateTime.utc(
                            day.year,
                            day.month,
                            day.day,
                          );
                          final isSelected = _uiSelectedDates.contains(
                            normalized,
                          );
                          final isSaved = _dbSavedDates.contains(normalized);

                          if (isSelected && isSaved) {
                            // Previously saved date — dark emerald
                            return Container(
                              margin: const EdgeInsets.all(4.0),
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: Color(0xFF047857),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${day.day}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            );
                          } else if (isSelected && !isSaved) {
                            // Newly selected date — bright green
                            return Container(
                              margin: const EdgeInsets.all(4.0),
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: Color(0xFF05A664),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${day.day}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            );
                          }
                          // Normal unselected day
                          return null;
                        },

                        // Selected builder (for tapped-then-saved dates)
                        selectedBuilder: (context, day, focusedDay) {
                          return null; // Handled by defaultBuilder
                        },
                      ),

                      // --- Calendar Style (fallback for unhandled states) ---
                      calendarStyle: const CalendarStyle(
                        cellMargin: EdgeInsets.all(4.0),

                        selectedDecoration: BoxDecoration(
                          color: Color(0xFF05A664),
                          shape: BoxShape.circle,
                        ),

                        todayDecoration: BoxDecoration(
                          color: Color(0xFF121415),
                          shape: BoxShape.circle,
                        ),

                        defaultTextStyle: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        weekendTextStyle: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        selectedTextStyle: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        todayTextStyle: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      daysOfWeekStyle: const DaysOfWeekStyle(
                        weekdayStyle: TextStyle(
                          color: Color(0xFF05A664),
                          fontWeight: FontWeight.bold,
                        ),
                        weekendStyle: TextStyle(
                          color: Color(0xFF05A664),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                // --- Add Poll Button ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 30.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveDates,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF05A664),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Add Poll",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
