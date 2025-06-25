import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skripsi/constants/app_colors.dart';
import 'package:skripsi/pages/users/request/leave_details_page.dart';
import 'package:skripsi/models/leave_request_model.dart';
import 'package:skripsi/pages/users/request/leave_request_form.dart';
import 'package:skripsi/providers/request_provider.dart';
import 'package:skripsi/services/leave_service.dart';
import 'package:skripsi/services/user_service.dart';
import 'package:skripsi/utility/date_extensions.dart';
import 'package:skripsi/widgets/confirmation_dialog.dart';
import 'package:skripsi/widgets/leave_summary_card.dart';

class RequestPage extends StatefulWidget {
  const RequestPage({super.key});

  @override
  State<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  bool _isDeleteMode = false;

  void _toggleDeleteMode() {
    setState(() {
      _isDeleteMode = !_isDeleteMode;
    });
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _confirmDelete(BuildContext context, LeaveRequest request) async {
    final leaveRequestProvider = Provider.of<LeaveRequestProvider>(context, listen: false);

    bool confirm = false;

    await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: "Confirm Deletion",
        content: "Are you sure you want to delete the request for ${request.leaveType}?",
        confirmText: "Delete",
        cancelText: "Cancel",
        onConfirm: () {
          confirm = true;
        },
      ),
    );

    if (confirm == true) {
      await leaveRequestProvider.removeLeaveRequest(request.id);
      _showSnackBar(context, "Leave request deleted successfully.");
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<LeaveRequestProvider>(context, listen: false).processPendingLeaveRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final leaveRequestProvider = Provider.of<LeaveRequestProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isDeleteMode ? Icons.check : Icons.delete, color: _isDeleteMode ? Colors.green : Colors.red),
            onPressed: _toggleDeleteMode,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FutureBuilder<DateTime>(
              future: UserService.getJoinDate(FirebaseAuth.instance.currentUser!.uid),
              builder: (context, joinDateSnapshot) {
                if (joinDateSnapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (joinDateSnapshot.hasError) {
                  return Text('Error: ${joinDateSnapshot.error}');
                }
                if (!joinDateSnapshot.hasData) {
                  return const Text('Join date not available.');
                }

                final joinDate = joinDateSnapshot.data!;

                return StreamBuilder<List<LeaveRequest>>(
                  stream: leaveRequestProvider.fetchLeaveRequests(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final leaveRequests = snapshot.data!;
                    return FutureBuilder<Map<String, dynamic>>(
                      future: LeaveService.computeLeaveSummary(leaveRequests, joinDate),
                      builder: (context, summarySnapshot) {
                        if (summarySnapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (summarySnapshot.hasError) {
                          return Text('Error: ${summarySnapshot.error}');
                        }
                        if (!summarySnapshot.hasData) {
                          return const Text('Unable to compute leave summary.');
                        }

                        final summary = summarySnapshot.data!;
                        return LeaveSummaryCard(summary: summary);
                      },
                    );
                  },
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<LeaveRequest>>(
              stream: leaveRequestProvider.fetchLeaveRequests(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final leaveRequests = snapshot.data ?? [];

                return ListView.builder(
                  itemCount: leaveRequests.length,
                  itemBuilder: (context, index) {
                    final request = leaveRequests[index];
                    return ListTile(
                      title: Text(request.leaveType),
                      subtitle: Text(_formatDate(request.startDate, request.endDate)),
                      trailing: IconButton(
                        icon: _isDeleteMode
                            ? const Icon(Icons.delete, color: Colors.red)
                            : _getStatusIcon(request.status),
                        onPressed: () {
                          if (_isDeleteMode) {
                            _confirmDelete(context, request);
                          }
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LeaveDetailsPage(
                              leaveType: request.leaveType,
                              startDate: request.startDate,
                              endDate: request.endDate,
                              reason: request.reason,
                              status: request.status,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => LeaveRequestForm(
                    onSubmit: (request) {
                      leaveRequestProvider.addLeaveRequest(request);
                      _showSnackBar(context, 'Leave request submitted successfully.');
                    },
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Apply Leave', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Icon _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'rejected':
        return const Icon(Icons.cancel, color: Colors.red);
      default:
        return const Icon(Icons.access_time_filled, color: Colors.orangeAccent);
    }
  }

  String _formatDate(DateTime startDate, DateTime endDate) {
    if (startDate.isAtSameMomentAs(endDate)) {
      return startDate.toFormattedString();
    }
    return '${startDate.toFormattedString()} to ${endDate.toFormattedString()}';
  }
}
