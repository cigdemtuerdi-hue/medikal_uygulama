import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/app_routes.dart';
import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_onboarding_models.dart';
import '../../services/onboarding_document_service.dart';
import '../../services/onboarding_service.dart';
import '../../services/ngo_partner_service.dart';
import '../../widgets/async_state_widgets.dart';
import '../../widgets/document_upload_card.dart';
import '../../widgets/us_address_autocomplete_field.dart';
import '../../widgets/ai_support_chat_widget.dart';
import '../app_shell.dart';

class ProfileCreationScreen extends StatefulWidget {
  const ProfileCreationScreen({
    super.key,
    required this.role,
  });

  final UserRole role;

  @override
  State<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _addressSearchController = TextEditingController();
  final _zipController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _orgNameController = TextEditingController();
  final _einController = TextEditingController();

  final _documentService = OnboardingDocumentService();
  final _onboardingService = OnboardingService();

  String? _idDocumentPath;
  String? _doctorReportPath;
  String? _conditionVideoPath;
  bool _isSubmitting = false;
  bool _manualAddressEntry = false;

  bool get _isRecipient => widget.role == UserRole.recipient;
  bool get _isNgo => widget.role == UserRole.ngoPartner;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _addressSearchController.dispose();
    _zipController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _orgNameController.dispose();
    _einController.dispose();
    super.dispose();
  }

  Future<void> _pickId(ImageSource source) async {
    final path = await _documentService.pickIdDocument(source);
    if (!mounted || path == null) return;
    setState(() => _idDocumentPath = path);
  }

  Future<void> _pickDoctorReport() async {
    final path = await _documentService.pickDoctorReport();
    if (!mounted || path == null) return;
    setState(() => _doctorReportPath = path);
  }

  Future<void> _pickConditionVideo() async {
    final path = await _documentService.pickConditionVideo();
    if (!mounted || path == null) return;
    setState(() => _conditionVideoPath = path);
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null) return;

    if (!formState.validate()) {
      _showMessage('Please complete all required fields.');
      return;
    }

    if (_idDocumentPath == null) {
      _showMessage('ID upload is required.');
      return;
    }

    if (_isRecipient) {
      if (_doctorReportPath == null) {
        _showMessage('Last 6 months medical report upload is required.');
        return;
      }
      if (_conditionVideoPath == null) {
        _showMessage('10-second introduction video upload is required.');
        return;
      }
    }

    if (_isNgo) {
      if (_orgNameController.text.trim().isEmpty) {
        _showMessage('Organization / foundation name is required.');
        return;
      }
      if (_einController.text.trim().isEmpty) {
        _showMessage('EIN (tax ID) is required for NGO verification.');
        return;
      }
    }

    setState(() => _isSubmitting = true);

    final profile = UserOnboardingProfile(
      role: widget.role,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      zipCode: _zipController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
      state: _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
      idDocumentPath: _idDocumentPath!,
      doctorReportPath: _doctorReportPath,
      conditionVideoPath: _conditionVideoPath,
      organizationName: _isNgo ? _orgNameController.text.trim() : null,
      organizationEin: _isNgo ? _einController.text.trim() : null,
    );

    await _onboardingService.saveProfile(profile);
    if (_isNgo) {
      NgoPartnerService.instance.activateSessionFromProfile(profile);
    }

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    final initialTab = switch (widget.role) {
      UserRole.donor => AppTab.home,
      UserRole.recipient => AppTab.recipient,
      UserRole.ngoPartner => AppTab.ngoPortal,
    };

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => AiSupportHost(
          child: AppShell(initialTab: initialTab),
        ),
      ),
      (route) => false,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _roleLabel(AppLocalizations loc) {
    return switch (widget.role) {
      UserRole.donor => loc.t('onboarding.role.donor'),
      UserRole.recipient => loc.t('onboarding.role.recipient'),
      UserRole.ngoPartner => loc.t('onboarding.role.ngo'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.t('onboarding.createProfile', {'role': _roleLabel(loc)}),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
          child: ContentConstrained(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.t('onboarding.personalInfo'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryDeepBlue,
                      ),
                ),
                if (_isNgo) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _orgNameController,
                    decoration: InputDecoration(
                      labelText: loc.t('onboarding.orgName'),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? loc.t('onboarding.orgNameRequired')
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _einController,
                    decoration: InputDecoration(
                      labelText: loc.t('onboarding.ein'),
                      hintText: loc.t('onboarding.einHint'),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? loc.t('onboarding.einRequired')
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.t('onboarding.ngoBadgeNote'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        decoration: InputDecoration(
                          labelText: loc.t('onboarding.firstName'),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) => value == null || value.trim().isEmpty
                            ? loc.t('onboarding.firstNameRequired')
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration: InputDecoration(
                          labelText: loc.t('onboarding.lastName'),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) => value == null || value.trim().isEmpty
                            ? loc.t('onboarding.lastNameRequired')
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: loc.t('onboarding.email'),
                    hintText: loc.t('onboarding.emailHint'),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty || !email.contains('@')) {
                      return loc.t('onboarding.emailInvalid');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: loc.t('onboarding.phone'),
                    hintText: loc.t('onboarding.phoneHint'),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    final phone = value?.trim() ?? '';
                    if (phone.length < 10) {
                      return loc.t('onboarding.phoneInvalid');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                UsAddressAutocompleteField(
                  controller: _addressSearchController,
                  labelText: loc.t('onboarding.addressOrZip'),
                  hintText: loc.t('onboarding.addressHint'),
                  onManualFallback: () =>
                      setState(() => _manualAddressEntry = true),
                  validator: (value) {
                    final zip = _zipController.text.trim();
                    if (zip.length == 5 && int.tryParse(zip) != null) {
                      return null;
                    }
                    if (_manualAddressEntry) {
                      return loc.t('onboarding.zipInvalid');
                    }
                    return loc.t('onboarding.addressSelectOrZip');
                  },
                  onAddressSelected: (suggestion) {
                    setState(() {
                      _addressSearchController.text = suggestion.primaryLine;
                      _zipController.text = suggestion.zipCode;
                      _cityController.text = suggestion.city;
                      _stateController.text = suggestion.state;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _zipController,
                        decoration: InputDecoration(
                          labelText: loc.t('onboarding.zipCode'),
                          hintText: loc.t('onboarding.zipHint'),
                        ),
                        keyboardType: TextInputType.number,
                        readOnly: !_manualAddressEntry,
                        enabled:
                            _manualAddressEntry || _zipController.text.isNotEmpty,
                        validator: _manualAddressEntry
                            ? (value) {
                                final zip = value?.trim() ?? '';
                                if (zip.length != 5 ||
                                    int.tryParse(zip) == null) {
                                  return loc.t('onboarding.zipInvalid');
                                }
                                return null;
                              }
                            : null,
                        onChanged: _manualAddressEntry
                            ? (_) => _formKey.currentState?.validate()
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _cityController,
                        decoration: InputDecoration(
                          labelText: loc.t('onboarding.city'),
                        ),
                        readOnly: !_manualAddressEntry,
                        enabled: _manualAddressEntry ||
                            _cityController.text.isNotEmpty,
                        textCapitalization: TextCapitalization.words,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _stateController,
                  decoration: InputDecoration(
                    labelText: loc.t('onboarding.state'),
                    hintText: loc.t('onboarding.stateHint'),
                  ),
                  readOnly: !_manualAddressEntry,
                  enabled:
                      _manualAddressEntry || _stateController.text.isNotEmpty,
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 32),
                Text(
                  loc.t('onboarding.identityVerification'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryDeepBlue,
                      ),
                ),
                const SizedBox(height: 12),
                DocumentUploadCard(
                  title: loc.t('onboarding.idUploadTitle'),
                  subtitle: loc.t('onboarding.idUploadSubtitle'),
                  icon: Icons.badge_outlined,
                  isUploaded: _idDocumentPath != null,
                  fileName: _documentService.fileLabel(_idDocumentPath),
                  onPickFromGallery: () => _pickId(ImageSource.gallery),
                  onPickFromCamera: () => _pickId(ImageSource.camera),
                ),
                if (_isRecipient) ...[
                  const SizedBox(height: 32),
                  Text(
                    loc.t('onboarding.medicalDocs'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDeepBlue,
                        ),
                  ),
                  const SizedBox(height: 12),
                  DocumentUploadCard(
                    title: loc.t('onboarding.doctorReportTitle'),
                    subtitle: loc.t('onboarding.doctorReportSubtitle'),
                    icon: Icons.description_outlined,
                    isUploaded: _doctorReportPath != null,
                    fileName: _documentService.fileLabel(_doctorReportPath),
                    onPickFile: _pickDoctorReport,
                  ),
                  const SizedBox(height: 16),
                  DocumentUploadCard(
                    title: loc.t('onboarding.videoTitle'),
                    subtitle: loc.t('onboarding.videoSubtitle'),
                    icon: Icons.videocam_outlined,
                    isUploaded: _conditionVideoPath != null,
                    fileName: _documentService.fileLabel(_conditionVideoPath),
                    onPickVideo: _pickConditionVideo,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: FilledButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting
                ? const InlineLoading()
                : const Icon(Icons.check_circle_outline),
            label: Text(
              _isSubmitting
                  ? loc.t('common.saving')
                  : loc.t('onboarding.completeProfile'),
            ),
          ),
        ),
      ),
    );
  }
}
