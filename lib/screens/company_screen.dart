import 'package:flutter/material.dart';
import 'package:super_admin/models/company_model.dart';
import '../services/supabase_service.dart';

class CompaniesScreen extends StatefulWidget {
  const CompaniesScreen({super.key});

  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {
  final SupabaseService _svc = SupabaseService();
  late Future<List<Company>> _futureCompanies;
  List<Company> _companies = [];
  String _searchQuery = '';
  String _selectedCategory = 'All'; // 'All', 'Active', 'Inactive'

  @override
  void initState() {
    super.initState();
    _futureCompanies = _loadCompanies();
  }

  Future<List<Company>> _loadCompanies() async {
    final list = await _svc.fetchCompanies();
    _companies = list;
    return list;
  }

  List<Company> _getFilteredCompanies(List<Company> companies) {
    return companies.where((company) {
      final matchesSearch = company.companyName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          company.companyNumber.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesCategory = _selectedCategory == 'All' ||
          (_selectedCategory == 'Active' && company.isActive) ||
          (_selectedCategory == 'Inactive' && !company.isActive);
      
      return matchesSearch && matchesCategory;
    }).toList();
  }

  Future<void> _toggleActive(Company company, bool newValue) async {
    final oldValue = company.isActive;

    // Optimistic UI update
    setState(() {
      company.isActive = newValue;
    });

    if (mounted) {
      _showStatusDialog(newValue, company.companyName);
    }

    try {
      await _svc.updateIsActive(company.id, newValue);
    } catch (e) {
      // Revert if failed
      setState(() {
        company.isActive = oldValue;
      });
      if (mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update ${company.companyName}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showStatusDialog(bool isActive, String companyName) {
    final themeColor = isActive ? const Color(0xFF2563EB) : const Color(0xFFEF4444);
    final icon = isActive ? Icons.check_circle_rounded : Icons.remove_circle_rounded;
    final title = isActive ? 'Company Activated' : 'Company Deactivated';
    final message = isActive
        ? '$companyName is now active.'
        : '$companyName has been set to inactive.';

    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: themeColor, size: 56),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4B5563),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(
                foregroundColor: themeColor,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _refresh() async {
    final list = await _svc.fetchCompanies();
    setState(() {
      _companies = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Company Management',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 24,
            letterSpacing: 0.5,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1D4ED8), Color(0xFF0EA5E9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
        ],
        elevation: 8,
      ),
      body: Container(
        color: const Color(0xFFF8FAFC),
        child: FutureBuilder<List<Company>>(
          future: _futureCompanies,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1D4ED8)),
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 60),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              );
            }

            final items = snapshot.data ?? _companies;
            final filteredItems = _getFilteredCompanies(items);

            return RefreshIndicator(
              onRefresh: _refresh,
              color: const Color(0xFF1D4ED8),
              child: Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                    child: SizedBox(
                      height: 42,
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search companies...',
                          hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF1D4ED8)),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Color(0xFF1D4ED8)),
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 1.4),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1.1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 1.4),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  // Category Tabs
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          _buildCategoryButton('All'),
                          _buildCategoryButton('Active'),
                          _buildCategoryButton('Inactive'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Company List
                  if (filteredItems.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.business, size: 80, color: Color(0xFFE0E0E0)),
                            const SizedBox(height: 16),
                            Text(
                              'No companies found.',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Color(0xFF757575),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final c = filteredItems[index];
                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c.companyName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1F1F1F),
                                            letterSpacing: 0.2,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'ID: ${c.companyNumber}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF757575),
                                            fontWeight: FontWeight.w400,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        c.isActive ? 'Active' : 'Inactive',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: c.isActive
                                              ? const Color(0xFF1D4ED8)
                                              : const Color(0xFFEF4444),
                                          letterSpacing: 0.1,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Transform.scale(
                                        scale: 0.9,
                                        child: Switch(
                                          value: c.isActive,
                                          onChanged: (val) => _toggleActive(c, val),
                                          activeColor: Colors.white,
                                          activeTrackColor: const Color(0xFF2563EB),
                                          inactiveThumbColor: Colors.white,
                                          inactiveTrackColor: const Color(0xFFB0BEC5),
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryButton(String category) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF1D4ED8), Color(0xFF0EA5E9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFE0E0E0),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1D4ED8).withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          category,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF424242),
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
