import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import '../services/firebase_service.dart';

class UserDashboardModal extends StatefulWidget {
  final int initialTabIndex;

  const UserDashboardModal({super.key, this.initialTabIndex = 0});

  static void show(BuildContext context, {int initialTabIndex = 0}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: UserDashboardModal(initialTabIndex: initialTabIndex),
      ),
    );
  }

  @override
  State<UserDashboardModal> createState() => _UserDashboardModalState();
}

class _UserDashboardModalState extends State<UserDashboardModal> {
  late int _selectedTab;

  // Profile Form Controllers
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  String _selectedAvatar = '⚡';

  // Company / B2B GST Controllers
  late TextEditingController _companyCtrl;
  late TextEditingController _gstinCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _pincodeCtrl;
  String _businessType = 'Private Limited (Pvt Ltd)';
  bool _isGstVerified = false;

  // Tracking Search Controller
  late TextEditingController _trackingSearchCtrl;
  Map<String, dynamic>? _foundTracking;

  // Demo / Mock Data for Projects and Orders
  final List<String> _avatars = ['⚡', '🤖', '🔬', '⚙️', '💻', '🚀', '🛰️', '🔋'];

  final List<Map<String, dynamic>> _mockProjects = [
    {
      'id': 'PRJ-2026-091',
      'name': 'High-Power Motor Driver Board v2.1',
      'layers': 4,
      'dimensions': '100mm × 80mm',
      'material': 'FR4 High-TG',
      'updated': '2 hours ago',
      'status': 'Ready for Quote',
    },
    {
      'id': 'PRJ-2026-084',
      'name': 'STM32 Microcontroller Mainboard',
      'layers': 2,
      'dimensions': '50mm × 50mm',
      'material': 'Standard FR4',
      'updated': 'Yesterday',
      'status': 'In Design',
    },
    {
      'id': 'PRJ-2026-072',
      'name': 'IoT Gateway Controller Rev B',
      'layers': 6,
      'dimensions': '120mm × 110mm',
      'material': 'Rogers RO4350B',
      'updated': '3 days ago',
      'status': 'Completed',
    },
  ];

  final List<Map<String, dynamic>> _mockOrders = [
    {
      'id': 'FF-ORD-98214',
      'date': '02 Sep 2026',
      'project': 'High-Power Motor Driver Board v2.1',
      'quantity': 10,
      'total': '₹4,850',
      'status': 'In Fabrication',
      'estDelivery': '03 Sep 2026 (8-Hour Express)',
      'trackingNo': 'FF-TRK-882109',
    },
    {
      'id': 'FF-ORD-97410',
      'date': '28 Aug 2026',
      'project': 'STM32 Microcontroller Mainboard',
      'quantity': 25,
      'total': '₹3,200',
      'status': 'Delivered',
      'estDelivery': '29 Aug 2026',
      'trackingNo': 'FF-TRK-771042',
    },
    {
      'id': 'FF-ORD-96102',
      'date': '15 Aug 2026',
      'project': 'IoT Gateway Controller Rev B',
      'quantity': 5,
      'total': '₹8,900',
      'status': 'Delivered',
      'estDelivery': '17 Aug 2026',
      'trackingNo': 'FF-TRK-665123',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex;

    final name = AuthService.userName ?? 'Jojumohan';
    final email = AuthService.userEmail ?? 'jojumohan@gmail.com';

    _nameCtrl = TextEditingController(text: name);
    _emailCtrl = TextEditingController(text: email);
    _phoneCtrl = TextEditingController(text: '+91 98765 43210');

    _companyCtrl = TextEditingController(text: 'FlashFabz Innovations Pvt Ltd');
    _gstinCtrl = TextEditingController(text: '29ABCDE1234F1Z5');
    _addressCtrl = TextEditingController(text: '102 Industrial Tech Park, Electronic City Phase 1');
    _cityCtrl = TextEditingController(text: 'Bengaluru, Karnataka');
    _pincodeCtrl = TextEditingController(text: '560100');

    _trackingSearchCtrl = TextEditingController(text: 'FF-TRK-882109');
    _foundTracking = _mockOrders[0];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _companyCtrl.dispose();
    _gstinCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _pincodeCtrl.dispose();
    _trackingSearchCtrl.dispose();
    super.dispose();
  }

  void _saveProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile details updated successfully!'),
        backgroundColor: Color(0xFF00E5FF),
      ),
    );
  }

  void _saveCompanyB2B() {
    setState(() => _isGstVerified = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('B2B Company & GSTIN verified and saved!'),
        backgroundColor: Color(0xFF00E676),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 850;

    return Container(
      width: isMobile ? size.width * 0.95 : 1000,
      height: isMobile ? size.height * 0.85 : 680,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A10),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.8),
            blurRadius: 50,
            spreadRadius: 10,
          ),
          BoxShadow(
            color: const Color(0xFF00E5FF).withOpacity(0.08),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Modal Header Topbar
          _buildHeader(context),

          const Divider(height: 1, color: Color(0xFF1E1E2D)),

          // Main Body (Sidebar Navigation + Tab Content)
          Expanded(
            child: isMobile
                ? Column(
                    children: [
                      _buildMobileTabBar(),
                      Expanded(child: _buildTabContent()),
                    ],
                  )
                : Row(
                    children: [
                      _buildDesktopSidebar(),
                      const VerticalDivider(width: 1, color: Color(0xFF1E1E2D)),
                      Expanded(child: _buildTabContent()),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ── Header Topbar ────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D111A), Color(0xFF080A10)],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00E5FF).withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.4)),
            ),
            child: Text(
              _selectedAvatar,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'User Account',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_isGstVerified)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF00E676).withOpacity(0.5)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, size: 12, color: Color(0xFF00E676)),
                          SizedBox(width: 4),
                          Text(
                            'B2B Verified',
                            style: TextStyle(
                              color: Color(0xFF00E676),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                _emailCtrl.text,
                style: const TextStyle(color: Color(0xFF8B8B9E), fontSize: 13),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 24),
            hoverColor: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
        ],
      ),
    );
  }

  // ── Desktop Sidebar ──────────────────────────────────────────────────────
  Widget _buildDesktopSidebar() {
    return Container(
      width: 240,
      color: const Color(0xFF07080E),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _navTile(0, Icons.person_outline, 'Edit Profile & Pic'),
          _navTile(1, Icons.business_outlined, 'Company & B2B GST'),
          _navTile(2, Icons.folder_copy_outlined, 'My Projects'),
          _navTile(3, Icons.receipt_long_outlined, 'Order History'),
          _navTile(4, Icons.local_shipping_outlined, 'Shipment Tracking'),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF00E5FF).withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.2)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bolt, color: Color(0xFF00E5FF), size: 16),
                    SizedBox(width: 6),
                    Text(
                      '8-Hour Priority Support',
                      style: TextStyle(
                        color: Color(0xFF00E5FF),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  'Need custom stackups or instant CAD review?',
                  style: TextStyle(color: Color(0xFF8B8B9E), fontSize: 10, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _mobileTabBtn(0, 'Profile'),
          _mobileTabBtn(1, 'Company & GST'),
          _mobileTabBtn(2, 'Projects'),
          _mobileTabBtn(3, 'Orders'),
          _mobileTabBtn(4, 'Tracking'),
        ],
      ),
    );
  }

  Widget _mobileTabBtn(int index, String label) {
    final active = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF00E5FF).withOpacity(0.15) : const Color(0xFF13131A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? const Color(0xFF00E5FF) : Colors.white10,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFF00E5FF) : Colors.white70,
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _navTile(int index, IconData icon, String label) {
    final active = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF00E5FF).withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? const Color(0xFF00E5FF).withOpacity(0.4) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: active ? const Color(0xFF00E5FF) : const Color(0xFF8B8B9E),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : const Color(0xFFB0B0C0),
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab Router ───────────────────────────────────────────────────────────
  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildEditProfileTab();
      case 1:
        return _buildCompanyB2BTab();
      case 2:
        return _buildProjectsTab();
      case 3:
        return _buildOrdersTab();
      case 4:
        return _buildTrackingTab();
      default:
        return _buildEditProfileTab();
    }
  }

  // ── 1. Edit Profile Tab ──────────────────────────────────────────────────
  Widget _buildEditProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tabHeading('Edit Profile & Picture', 'Manage your personal account details and avatar'),
          const SizedBox(height: 24),

          // Profile Avatar Picker
          const Text('Choose Profile Avatar / Icon',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _avatars.map((avatar) {
              final selected = _selectedAvatar == avatar;
              return GestureDetector(
                onTap: () => setState(() => _selectedAvatar = avatar),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF00E5FF).withOpacity(0.2)
                        : const Color(0xFF13131A),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? const Color(0xFF00E5FF) : Colors.white10,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Text(avatar, style: const TextStyle(fontSize: 22)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // Fields
          Row(
            children: [
              Expanded(child: _field('Full Name', Icons.person_outline, _nameCtrl)),
              const SizedBox(width: 16),
              Expanded(child: _field('Phone Number', Icons.phone_outlined, _phoneCtrl)),
            ],
          ),
          const SizedBox(height: 16),
          _field('Email Address', Icons.email_outlined, _emailCtrl, readOnly: true),
          const SizedBox(height: 28),

          // Save Button
          ElevatedButton.icon(
            onPressed: _saveProfile,
            icon: const Icon(Icons.save_rounded, color: Colors.black, size: 18),
            label: const Text('Save Profile Changes',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Company & B2B GST Tab ─────────────────────────────────────────────
  Widget _buildCompanyB2BTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tabHeading('Company Details & B2B GSTIN',
              'Add your registered business GST details for B2B tax invoices'),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(child: _field('Company / Business Name', Icons.business_outlined, _companyCtrl)),
              const SizedBox(width: 16),
              Expanded(
                child: _field('GSTIN Number (e.g. 29ABCDE1234F1Z5)', Icons.verified_user_outlined, _gstinCtrl),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Text('Business Entity Type',
              style: TextStyle(color: Color(0xFF8B8B9E), fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _businessType,
                dropdownColor: const Color(0xFF13131A),
                isExpanded: true,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                items: const [
                  DropdownMenuItem(value: 'Private Limited (Pvt Ltd)', child: Text('Private Limited (Pvt Ltd)')),
                  DropdownMenuItem(value: 'Proprietorship / LLP', child: Text('Proprietorship / LLP')),
                  DropdownMenuItem(value: 'Individual / Hardware Designer', child: Text('Individual / Hardware Designer')),
                  DropdownMenuItem(value: 'R&D Lab / Educational Institute', child: Text('R&D Lab / Educational Institute')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _businessType = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          _field('Registered Billing Address', Icons.location_on_outlined, _addressCtrl),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(child: _field('City / State', Icons.location_city, _cityCtrl)),
              const SizedBox(width: 16),
              Expanded(child: _field('Pincode / ZIP', Icons.pin_drop_outlined, _pincodeCtrl)),
            ],
          ),
          const SizedBox(height: 28),

          ElevatedButton.icon(
            onPressed: _saveCompanyB2B,
            icon: const Icon(Icons.check_circle_rounded, color: Colors.black, size: 18),
            label: const Text('Save & Verify B2B GST',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. My Projects Tab ───────────────────────────────────────────────────
  Widget _buildProjectsTab() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _tabHeading('My PCB Projects', 'Manage saved Gerber designs and layer stackups'),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.upload_file, color: Colors.black, size: 16),
                label: const Text('Upload New Gerber', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Expanded(
            child: ListView.separated(
              itemCount: _mockProjects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final proj = _mockProjects[index];
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13131A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.developer_board, color: Color(0xFF00E5FF), size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              proj['name'],
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ID: ${proj['id']}  •  ${proj['layers']} Layers  •  ${proj['dimensions']}  •  ${proj['material']}',
                              style: const TextStyle(color: Color(0xFF8B8B9E), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD54F).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFFD54F).withOpacity(0.4)),
                        ),
                        child: Text(
                          proj['status'],
                          style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. Order History Tab ("older section") ──────────────────────────────
  Widget _buildOrdersTab() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tabHeading('Order History & Invoices', 'View past PCB orders and manufacturing records'),
          const SizedBox(height: 20),

          Expanded(
            child: ListView.separated(
              itemCount: _mockOrders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final ord = _mockOrders[index];
                final isExpress = ord['status'] == 'In Fabrication';
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13131A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isExpress ? const Color(0xFF00E5FF).withOpacity(0.3) : Colors.white.withOpacity(0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            ord['id'],
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isExpress
                                  ? const Color(0xFF00E5FF).withOpacity(0.15)
                                  : const Color(0xFF00E676).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isExpress ? const Color(0xFF00E5FF) : const Color(0xFF00E676),
                              ),
                            ),
                            child: Text(
                              ord['status'],
                              style: TextStyle(
                                color: isExpress ? const Color(0xFF00E5FF) : const Color(0xFF00E676),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            ord['total'],
                            style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Item: ${ord['project']} (${ord['quantity']} pcs)',
                        style: const TextStyle(color: Color(0xFFB0B0C0), fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ordered on: ${ord['date']}  •  Est Delivery: ${ord['estDelivery']}',
                        style: const TextStyle(color: Color(0xFF8B8B9E), fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── 5. Shipment Tracking Tab ──────────────────────────────────────────────
  Widget _buildTrackingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tabHeading('Shipping & Live Order Tracking', 'Track live fabrication status and courier dispatch'),
          const SizedBox(height: 24),

          // Search tracking box
          Row(
            children: [
              Expanded(
                child: _field('Enter Order ID or Tracking No (e.g. FF-TRK-882109)', Icons.search, _trackingSearchCtrl),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _foundTracking = _mockOrders[0];
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Track Order', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 28),

          if (_foundTracking != null) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF13131A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_shipping, color: Color(0xFF00E5FF), size: 28),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tracking ID: ${_foundTracking!['trackingNo']}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                          Text(
                            'Courier: DHL Express  •  8-Hour Delivery Slot',
                            style: const TextStyle(color: Color(0xFF8B8B9E), fontSize: 12),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'IN TRANSIT (FAST-TRACK)',
                          style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.w800, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Progress Timeline Steps
                  _trackingStep('Order Placed & Gerber Verified', 'Completed at 09:30 AM', true),
                  _trackingStep('CNC Drilling & Etching Process', 'Completed at 11:45 AM', true),
                  _trackingStep('Flying Probe & Automated Optical Inspection (AOI)', 'Completed at 01:15 PM', true),
                  _trackingStep('Dispatched via DHL Priority Flight', 'In Progress — Estimated Arrival 05:00 PM', true, isCurrent: true),
                  _trackingStep('Final Delivery', 'Pending', false),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _trackingStep(String title, String subtitle, bool isDone, {bool isCurrent = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCurrent
                    ? const Color(0xFF00E5FF)
                    : (isDone ? const Color(0xFF00E676) : const Color(0xFF20202D)),
                border: Border.all(
                  color: isCurrent ? Colors.white : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Icon(
                isDone ? Icons.check : Icons.circle,
                size: 12,
                color: isDone ? Colors.black : Colors.white38,
              ),
            ),
            Container(
              width: 2,
              height: 32,
              color: isDone ? const Color(0xFF00E676).withOpacity(0.5) : const Color(0xFF20202D),
            ),
          ],
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isCurrent ? const Color(0xFF00E5FF) : (isDone ? Colors.white : Colors.white38),
                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF8B8B9E), fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  // ── Helper Widgets ───────────────────────────────────────────────────────
  Widget _tabHeading(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Color(0xFF8B8B9E), fontSize: 13)),
      ],
    );
  }

  Widget _field(String label, IconData icon, TextEditingController ctrl, {bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF8B8B9E), fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          readOnly: readOnly,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF00E5FF), size: 18),
            filled: true,
            fillColor: readOnly ? Colors.white.withOpacity(0.03) : const Color(0xFF0D0D14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
