import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/chat_provider.dart';
import '../providers/customer_provider.dart';
import '../config/constants.dart';

class PesanTab extends StatefulWidget {
  const PesanTab({super.key});

  @override
  State<PesanTab> createState() => _PesanTabState();
}

class _PesanTabState extends State<PesanTab> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _hasText = false;
  bool _showScrollToBottom = false;
  bool _showFaqSubmenu = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initChat();
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final isScrolledUp = (maxScroll - currentScroll) > 160;
    if (isScrolledUp != _showScrollToBottom) {
      setState(() {
        _showScrollToBottom = isScrolledUp;
      });
    }
  }

  String _getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final uri = Uri.parse(AppConstants.apiBaseUrl);
    final rootUrl = '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
    return '$rootUrl${path.startsWith('/') ? '' : '/'}$path';
  }

  void _onTextChanged() {
    final hasContent = _textController.text.trim().isNotEmpty;
    if (hasContent != _hasText) {
      setState(() {
        _hasText = hasContent;
      });
    }

    // Beritahu socket bahwa customer sedang mengetik
    final chatProvider = context.read<ChatProvider>();
    chatProvider.notifyTyping(hasContent);
  }

  void _initChat() {
    final custProvider = context.read<CustomerProvider>();
    final chatProvider = context.read<ChatProvider>();

    if (custProvider.customerData != null) {
      final p = custProvider.customerData!.pelanggan;
      chatProvider.initChat(
        pelangganId: p.id,
        brand: custProvider.isJelantik ? 'Jelantik' : 'Jakinet',
        name: p.nama.isNotEmpty ? p.nama : 'Pelanggan',
      );
    }
    chatProvider.setChatTabActive(true);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _scrollController.removeListener(_onScroll);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage([String? textToSend]) {
    final message = textToSend ?? _textController.text.trim();
    if (message.isEmpty) return;

    final chatProvider = context.read<ChatProvider>();

    // Cek apakah pesan adalah quick command bot / FAQ (misal ketik 1, 2, 1.1, dll)
    if (chatProvider.handleQuickInput(message)) {
      if (textToSend == null) {
        _textController.clear();
      }
      chatProvider.notifyTyping(false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
      return;
    }

    chatProvider.sendMessage(message);

    if (textToSend == null) {
      _textController.clear();
    }
    chatProvider.notifyTyping(false);

    // Auto scroll setelah frame ter-render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (pickedFile == null) return;

      final file = File(pickedFile.path);
      if (!mounted) return;

      _showImagePreviewDialog(file);
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih foto: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Kirim Foto / Gambar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildPickerOption(
                        icon: Icons.camera_alt_rounded,
                        label: 'Kamera',
                        color: const Color(0xFF2563EB),
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickImage(ImageSource.camera);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPickerOption(
                        icon: Icons.photo_library_rounded,
                        label: 'Galeri',
                        color: const Color(0xFF059669),
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickImage(ImageSource.gallery);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePreviewDialog(File file) {
    final captionController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final primaryColor = Theme.of(context).primaryColor;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Kirim Foto',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                            onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.35,
                          ),
                          width: double.infinity,
                          color: const Color(0xFFF1F5F9),
                          child: Image.file(
                            file,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: TextField(
                          controller: captionController,
                          enabled: !isSubmitting,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1E293B),
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Tambahkan keterangan (opsional)...',
                            hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            filled: false,
                            fillColor: Colors.transparent,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Batal',
                                style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      setModalState(() {
                                        isSubmitting = true;
                                      });
                                      final chatProvider = context.read<ChatProvider>();
                                      final success = await chatProvider.uploadAndSendImage(
                                        file,
                                        caption: captionController.text.trim(),
                                      );
                                      if (ctx.mounted) {
                                        Navigator.pop(ctx);
                                      }
                                      if (success) {
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          _scrollToBottom();
                                        });
                                      } else if (mounted) {
                                        ScaffoldMessenger.of(this.context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Gagal mengunggah foto. Silakan coba lagi.'),
                                            backgroundColor: Color(0xFFEF4444),
                                          ),
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.send_rounded, size: 18, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text(
                                          'Kirim',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openWhatsApp(String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch WhatsApp link $urlString: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final custProvider = context.watch<CustomerProvider>();
    final chatProvider = context.watch<ChatProvider>();
    final primaryColor = Theme.of(context).primaryColor;
    final isJelantik = custProvider.isJelantik;

    // Warna aksen bubble chat customer (lembut dan kontras)
    final userBubbleColor = isJelantik
        ? const Color(0xFFEBF3FF) // Soft Blue for Jelantik
        : const Color(0xFFFEECEB); // Soft Red for Jakinet

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Modern clean background
      body: Column(
        children: [
          // 1. TOP HEADER BAR
          _buildHeaderBar(custProvider, chatProvider, primaryColor),

          // 2. CHAT MESSAGES AREA
          Expanded(
            child: Stack(
              children: [
                chatProvider.isLoadingHistory && chatProvider.messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: primaryColor),
                            const SizedBox(height: 12),
                            const Text(
                              'Memuat percakapan...',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await chatProvider.fetchHistory();
                        },
                        color: primaryColor,
                        child: chatProvider.messages.isEmpty
                            ? _buildEmptyState(primaryColor, custProvider)
                            : _buildMessageList(chatProvider, userBubbleColor, primaryColor),
                      ),

                // Tombol Mengambang (Floating Action) Langsung ke Chat Terakhir
                if (_showScrollToBottom)
                  Positioned(
                    bottom: 12,
                    right: 14,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 3,
                      shadowColor: Colors.black.withValues(alpha: 0.25),
                      child: InkWell(
                        onTap: _scrollToBottom,
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                          ),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF334155),
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 3. TYPING INDICATOR (JIKA CS SEDANG MENGETIK)
          if (chatProvider.isOtherTyping) _buildTypingIndicator(primaryColor),

          // 4. QUICK BOT & FAQ MENU BAR (Pilihan 1 & 2)
          _buildQuickBotMenuBar(chatProvider, primaryColor),

          // 5. BOTTOM INPUT BAR
          _buildInputBar(primaryColor),
        ],
      ),
    );
  }

  Widget _buildHeaderBar(
    CustomerProvider custProvider,
    ChatProvider chatProvider,
    Color primaryColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar CS dengan Indikator Online/Offline
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: primaryColor.withValues(alpha: 0.12),
                child: Icon(Icons.support_agent_rounded, color: primaryColor, size: 24),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: chatProvider.isConnected ? const Color(0xFF22C55E) : const Color(0xFF94A3B8),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Nama CS & Status Realtime
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Customer Support',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  chatProvider.isOtherTyping
                      ? 'sedang mengetik...'
                      : chatProvider.isConnected
                          ? 'Online  Siap membantu'
                          : 'Menghubungkan ke server...',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: chatProvider.isOtherTyping ? FontStyle.italic : FontStyle.normal,
                    color: chatProvider.isOtherTyping
                        ? primaryColor
                        : chatProvider.isConnected
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF94A3B8),
                    fontWeight: chatProvider.isOtherTyping ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),

          // Tombol Alternatif WhatsApp Resmi
          InkWell(
            onTap: () {
              final waUrl = custProvider.isJelantik
                  ? AppConstants.jelantikWhatsapp
                  : AppConstants.jakinetWhatsapp;
              _openWhatsApp(waUrl);
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Color(0xFF16A34A)),
                  SizedBox(width: 4),
                  Text(
                    'WhatsApp',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color primaryColor, CustomerProvider custProvider) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_rounded,
              size: 48,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Mulai Obrolan Langsung',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tim Customer Care kami siap membantu segala pertanyaan dan kendala internet Anda secara langsung di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Quick Questions / Suggestions
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Icon(Icons.smart_toy_outlined, size: 16, color: primaryColor),
                const SizedBox(width: 6),
                Text(
                  'Pilihan Bantuan & Menu Cepat:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildQuickMenuCard(
            title: '1. 📋 Bantuan Cepat / FAQ Template',
            subtitle: 'Solusi instan kendala WiFi lambat, lampu LOS, tagihan & restart modem',
            color: const Color(0xFF2563EB),
            icon: Icons.help_center_outlined,
            onTap: () {
              final chatProvider = context.read<ChatProvider>();
              chatProvider.handleQuickInput('1');
              WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
            },
          ),
          _buildQuickMenuCard(
            title: '2. 👤 Hubungkan ke Customer Support (CS)',
            subtitle: 'Tersambung langsung dengan tim representatif agen CS kami',
            color: const Color(0xFF059669),
            icon: Icons.support_agent_rounded,
            onTap: () {
              final chatProvider = context.read<ChatProvider>();
              chatProvider.requestConnectToAgent();
              WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Atau pilih kendala spesifik:',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 6),
          _buildQuickAction('1.1 📶 Kendala WiFi Lambat / Sinyal Lemah'),
          _buildQuickAction('1.2 🔴 Lampu Indikator LOS Menyala Merah'),
          _buildQuickAction('1.3 💳 Info Tagihan & Cara Pembayaran'),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => _sendMessage(text),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.white,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickMenuCard({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      width: double.infinity,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 0.5,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.25), width: 1.2),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickBotMenuBar(ChatProvider chatProvider, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row tombol utama 1 & 2
          Row(
            children: [
              // 1. Bantuan Cepat / FAQ
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _showFaqSubmenu = !_showFaqSubmenu;
                    });
                    if (_showFaqSubmenu) {
                      chatProvider.handleQuickInput('1');
                      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: _showFaqSubmenu ? const Color(0xFF2563EB) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _showFaqSubmenu ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.help_center_outlined,
                          size: 15,
                          color: _showFaqSubmenu ? Colors.white : const Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '1. Bantuan FAQ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _showFaqSubmenu ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 2. Hubungkan ke CS
              Expanded(
                child: InkWell(
                  onTap: () {
                    chatProvider.requestConnectToAgent();
                    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: chatProvider.isConnectedToAgent ? const Color(0xFF059669) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: chatProvider.isConnectedToAgent ? const Color(0xFF059669) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.support_agent_rounded,
                          size: 15,
                          color: chatProvider.isConnectedToAgent ? Colors.white : const Color(0xFF059669),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          chatProvider.isConnectedToAgent ? 'Terhubung CS' : '2. Hubungkan CS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: chatProvider.isConnectedToAgent ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Submenu Horizontal Scrolling Chips jika tombol FAQ ditekan
          if (_showFaqSubmenu) ...[
            const SizedBox(height: 6),
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ...ChatProvider.faqList.map((faq) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        padding: EdgeInsets.zero,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                        avatar: const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFF2563EB)),
                        label: Text(
                          faq.shortTitle,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                        ),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        onPressed: () {
                          chatProvider.sendFaqAnswer(faq);
                          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                        },
                      ),
                    );
                  }),
                  // Tombol Tutup Submenu
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showFaqSubmenu = false;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.close_rounded, size: 14, color: Color(0xFF64748B)),
                          SizedBox(width: 2),
                          Text('Tutup', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageList(
    ChatProvider chatProvider,
    Color userBubbleColor,
    Color primaryColor,
  ) {
    final messages = chatProvider.messages;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final isMe = msg.isMe;
        final isSystem = msg.senderType == 'system';

        // Date separator check
        bool showDateHeader = false;
        if (index == 0) {
          showDateHeader = true;
        } else {
          final prevMsg = messages[index - 1];
          if (prevMsg.createdAt.day != msg.createdAt.day ||
              prevMsg.createdAt.month != msg.createdAt.month ||
              prevMsg.createdAt.year != msg.createdAt.year) {
            showDateHeader = true;
          }
        }

        return Column(
          children: [
            if (showDateHeader) _buildDateHeader(msg.createdAt),
            Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.82,
                ),
                decoration: BoxDecoration(
                  color: isMe
                      ? userBubbleColor
                      : isSystem
                          ? const Color(0xFFF8FAFC)
                          : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(14),
                    topRight: const Radius.circular(14),
                    bottomLeft: Radius.circular(isMe ? 14 : 2),
                    bottomRight: Radius.circular(isMe ? 2 : 14),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                  border: Border.all(
                    color: isMe
                        ? primaryColor.withValues(alpha: 0.18)
                        : isSystem
                            ? const Color(0xFF93C5FD).withValues(alpha: 0.7)
                            : const Color(0xFFE2E8F0),
                    width: 0.8,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment:
                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Sender label for Admin/CS or System Bot
                    if (!isMe) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSystem ? Icons.smart_toy_rounded : Icons.verified,
                            size: 13,
                            color: isSystem ? const Color(0xFF2563EB) : primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isSystem
                                ? 'Asisten Virtual'
                                : (msg.senderName.isNotEmpty ? msg.senderName : 'Customer Support'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSystem ? const Color(0xFF2563EB) : primaryColor,
                            ),
                          ),
                          if (isSystem) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDBEAFE),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Auto Bot',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1D4ED8),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],

                    // Lampiran Gambar jika ada
                    if ((msg.attachmentUrl != null && msg.attachmentUrl!.isNotEmpty) ||
                        msg.messageType == 'image') ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: GestureDetector(
                          onTap: () {
                            final fullUrl = _getFullImageUrl(msg.attachmentUrl);
                            if (fullUrl.isNotEmpty) {
                              showDialog(
                                context: context,
                                builder: (_) => Dialog(
                                  backgroundColor: Colors.black.withValues(alpha: 0.85),
                                  insetPadding: const EdgeInsets.all(12),
                                  child: Stack(
                                    alignment: Alignment.topRight,
                                    children: [
                                      Center(
                                        child: InteractiveViewer(
                                          child: Image.network(
                                            fullUrl,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: CircleAvatar(
                                          backgroundColor: Colors.black54,
                                          child: IconButton(
                                            icon: const Icon(Icons.close, color: Colors.white),
                                            onPressed: () => Navigator.of(context).pop(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          },
                          child: Hero(
                            tag: 'img_${msg.id ?? msg.tempId}',
                            child: Image.network(
                              _getFullImageUrl(msg.attachmentUrl),
                              fit: BoxFit.cover,
                              width: 240,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: 240,
                                  height: 180,
                                  color: const Color(0xFFF1F5F9),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: primaryColor,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 240,
                                  height: 120,
                                  color: const Color(0xFFF1F5F9),
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image_rounded, color: Colors.grey[400], size: 32),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Gagal memuat gambar',
                                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      if (msg.message.isNotEmpty) const SizedBox(height: 6),
                    ],

                    // Pesan Teks
                    if (msg.message.isNotEmpty)
                      Text(
                        msg.message,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1E293B),
                          height: 1.35,
                        ),
                      ),

                    // Interactive Action Buttons jika pesan dari Virtual Assistant / System
                    if (isSystem) ...[
                      // 1. Jika pesan menawarkan opsi hubungkan ke CS
                      if (msg.message.contains('Hubungkan ke CS') || msg.message.contains('2. Hubungkan ke CS')) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              chatProvider.requestConnectToAgent();
                              WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                            },
                            icon: const Icon(Icons.support_agent_rounded, size: 16, color: Colors.white),
                            label: const Text(
                              'Hubungkan ke Tim CS',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],

                      // 2. Jika pesan adalah menu FAQ (berisi opsi topik)
                      if (msg.message.contains('Pilih topik') || msg.message.contains('1.1')) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: ChatProvider.faqList.map((faq) {
                            return InkWell(
                              onTap: () {
                                chatProvider.sendFaqAnswer(faq);
                                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF93C5FD)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.help_outline_rounded, size: 13, color: Color(0xFF2563EB)),
                                    const SizedBox(width: 4),
                                    Text(
                                      faq.shortTitle,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                    const SizedBox(height: 4),

                    // Timestamp & Status Ceklis (ala WhatsApp)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(msg.createdAt),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          _buildStatusIcon(msg.status),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    String label;
    if (messageDate == today) {
      label = 'Hari Ini';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      label = 'Kemarin';
    } else {
      label = DateFormat('dd MMMM yyyy', 'id_ID').format(date);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return const Icon(
          Icons.access_time_rounded,
          size: 13,
          color: Color(0xFF94A3B8),
        );
      case 'sent':
        return const Icon(
          Icons.check_rounded,
          size: 14,
          color: Color(0xFF94A3B8),
        );
      case 'delivered':
        return const Icon(
          Icons.done_all_rounded,
          size: 15,
          color: Color(0xFF94A3B8),
        );
      case 'read':
        return const Icon(
          Icons.done_all_rounded,
          size: 15,
          color: Color(0xFF34B7F1),
        );
      default:
        return const Icon(
          Icons.check_rounded,
          size: 14,
          color: Color(0xFF94A3B8),
        );
    }
  }

  Widget _buildTypingIndicator(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      alignment: Alignment.centerLeft,
      color: Colors.transparent,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: primaryColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Customer Support sedang mengetik...',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Unified Input Pill (Menampung Icon Lampiran Foto & TextField)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                ),
                padding: const EdgeInsets.only(left: 4, right: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Tombol Lampiran Foto / Gambar
                    IconButton(
                      icon: const Icon(
                        Icons.add_photo_alternate_outlined,
                        color: Color(0xFF64748B),
                        size: 22,
                      ),
                      onPressed: _showAttachmentOptions,
                      splashRadius: 20,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      tooltip: 'Kirim Foto',
                    ),

                    // Kolom Input Teks (Dengan reset border agar tidak terjadi border bertumpuk)
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        minLines: 1,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1E293B),
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Ketik pesan Anda...',
                          hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          filled: false,
                          fillColor: Colors.transparent,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Tombol Kirim Bulat
            Material(
              color: _hasText ? primaryColor : const Color(0xFFE2E8F0),
              shape: const CircleBorder(),
              elevation: _hasText ? 1.5 : 0,
              shadowColor: primaryColor.withValues(alpha: 0.3),
              child: InkWell(
                onTap: _hasText ? () => _sendMessage() : null,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(
                    Icons.send_rounded,
                    color: _hasText ? Colors.white : const Color(0xFF94A3B8),
                    size: 19,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
