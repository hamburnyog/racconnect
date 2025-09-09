import 'package:flutter/material.dart';
import 'package:racconnect/data/models/profile_model.dart';
import 'package:racconnect/data/models/user_model.dart';
import 'package:racconnect/data/repositories/auth_repository.dart';
import 'package:racconnect/utility/constants.dart';

String? getPocketBaseFileUrl(String? filename, String? recordId) {
  if (filename == null ||
      filename.isEmpty ||
      recordId == null ||
      recordId.isEmpty) {
    return null;
  }
  return '$serverUrl/api/files/_pb_users_auth_/$recordId/$filename';
}

class UserMultiSelect extends StatefulWidget {
  final Function(List<ProfileModel>) onSelectionChanged;
  final List<ProfileModel> selectedEmployees;

  const UserMultiSelect(
      {super.key, required this.onSelectionChanged, required this.selectedEmployees});

  @override
  State<UserMultiSelect> createState() => _UserMultiSelectState();
}

class _UserMultiSelectState extends State<UserMultiSelect> {
  final TextEditingController searchController = TextEditingController();
  List<UserModel> allUsers = [];
  List<ProfileModel> allProfiles = [];
  List<ProfileModel> filteredProfiles = [];
  bool isLoadingProfiles = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    searchController.addListener(() {
      filterProfiles();
    });
  }

  void filterProfiles() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredProfiles = allProfiles.where((profile) {
        final fullName =
            '${profile.firstName} ${profile.middleName ?? ''} ${profile.lastName}'
                .toLowerCase();
        final sectionCode = profile.sectionCode?.toLowerCase() ?? '';
        final employeeNumber = profile.employeeNumber?.toLowerCase() ?? '';

        return fullName.contains(query) ||
            sectionCode.contains(query) ||
            employeeNumber.contains(query);
      }).toList();
    });
  }

  Future<void> _loadUsers() async {
    setState(() {
      isLoadingProfiles = true;
    });

    try {
      final authRepository = AuthRepository();
      final users = await authRepository.getUsers();

      // Filter profiles to only include those with a role (not null)
      allUsers = users
          .where(
            (user) =>
                user.role != null &&
                user.role!.isNotEmpty &&
                user.profile != null &&
                user.profile!.employmentStatus != 'Resigned' &&
                user.profile!.employmentStatus != 'Retired' &&
                user.profile!.employeeNumber != null &&
                user.profile!.employeeNumber!.isNotEmpty,
          )
          .toList();

      allProfiles = allUsers.map((user) => user.profile!).toList();

      if (mounted) {
        setState(() {
          isLoadingProfiles = false;
          filteredProfiles = allProfiles;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingProfiles = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading employees: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleEmployeeSelection(ProfileModel profile) {
    setState(() {
      if (widget.selectedEmployees.contains(profile)) {
        widget.selectedEmployees.remove(profile);
      } else {
        widget.selectedEmployees.add(profile);
      }
      widget.onSelectionChanged(widget.selectedEmployees);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.selectedEmployees.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  alignment: WrapAlignment.start,
                  children: widget.selectedEmployees.map((employee) {
                    return Chip(
                      label: Text(
                        '${employee.lastName}, ${employee.firstName.isNotEmpty ? employee.firstName[0] : ''}.'
                            .toUpperCase(),
                      ),
                      backgroundColor: Theme.of(context).primaryColor,
                      labelStyle: const TextStyle(
                        color: Colors.white,
                      ),
                      deleteIconColor: Colors.white,
                      onDeleted: () {
                        _toggleEmployeeSelection(employee);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        const SizedBox(height: 20),
        TextFormField(
          controller: searchController,
          decoration: const InputDecoration(
            labelText: 'Search by employee number, name or section',
            hintText: 'Enter name, section, or employee number',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        if (isLoadingProfiles)
          const Center(child: CircularProgressIndicator())
        else ...[
          SizedBox(
            height: 200,
            child: ListView.builder(
              itemCount: filteredProfiles.length,
              itemBuilder: (context, index) {
                final profile = filteredProfiles[index];
                final user = allUsers.firstWhere(
                  (user) => user.profile == profile,
                );
                final isSelected = widget.selectedEmployees.contains(
                  profile,
                );
                final avatarUrl = getPocketBaseFileUrl(
                  user.avatar,
                  user.id,
                );
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (value) {
                    _toggleEmployeeSelection(profile);
                  },
                  secondary: CircleAvatar(
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? Text(
                            profile.firstName.isNotEmpty ? profile.firstName[0] : ' ',
                          )
                        : null,
                  ),
                  title: Text(
                    '${profile.employeeNumber} - ${profile.lastName}, ${profile.firstName.isNotEmpty ? profile.firstName[0] : ''}.'
                        .toUpperCase(),
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    'Section: ${profile.sectionCode}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
