import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/profile_address.dart';
import '../models/user_onboarding_models.dart';
import '../services/auth_session_service.dart';
import '../services/ngo_partner_service.dart';
import '../services/onboarding_document_service.dart';
import '../services/onboarding_service.dart';
import '../services/profile_address_service.dart';
import '../widgets/async_state_widgets.dart';
import '../widgets/document_upload_card.dart';
import '../widgets/hipaa_consent_widgets.dart';
import '../widgets/us_address_autocomplete_field.dart';
import '../services/compliance_api_service.dart';

/// Edit the same personal details collected during signup.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.initialProfile});

  final UserOnboardingProfile initialProfile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
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
  final _addressService = ProfileAddressService.instance;

  late String _idDocumentPath;
  String? _doctorReportPath;
  String? _conditionVideoPath;
  bool _isSubmitting = false;
  bool _manualAddressEntry = false;
  bool _hipaaConsentAccepted = false;
  String? _hipaaConsentError;

  bool get _isRecipient => widget.initialProfile.role == UserRole.recipient;
  bool get _isNgo => widget.initialProfile.role == UserRole.ngoPartner;

  @override
  void initState() {
    super.initState();
    final p = widget.initialProfile;
    _firstNameController.text = p.firstName;
    _lastNameController.text = p.lastName;
    _emailController.text = p.email;
    _phoneController.text = p.phone;
    _zipController.text = p.zipCode;
    _cityController.text = p.city ?? '';
    _stateController.text = p.state ?? '';
    _orgNameController.text = p.organizationName ?? '';
    _einController.text = p.organizationEin ?? '';
    _idDocumentPath = p.idDocumentPath;
    _doctorReportPath = p.doctorReportPath;
    _conditionVideoPath = p.conditionVideoPath;

    final city = p.city ?? '';
    final state = p.state ?? '';
    if (city.isNotEmpty && state.isNotEmpty && p.zipCode.isNotEmpty) {
      _addressSearchController.text = '$city, $state ${p.zipCode}';
    } else if (p.zipCode.isNotEmpty) {
      _addressSearchController.text = p.zipCode;
    }
  }

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
    final loc = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('profile.editValidation'))),
      );
      return;
    }

    if (_idDocumentPath.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('onboarding.idUploadTitle'))),
      );
      return;
    }

    if (_isRecipient && !_hipaaConsentAccepted) {
      setState(() => _hipaaConsentError = loc.t('hipaa.requiredError'));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('hipaa.requiredError'))),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final updated = widget.initialProfile.copyWith(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      zipCode: _zipController.text.trim(),
      city: _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim(),
      state: _stateController.text.trim().isEmpty
          ? null
          : _stateController.text.trim(),
      idDocumentPath: _idDocumentPath,
      doctorReportPath: _doctorReportPath,
      conditionVideoPath: _conditionVideoPath,
      organizationName: _isNgo ? _orgNameController.text.trim() : null,
      organizationEin: _isNgo ? _einController.text.trim() : null,
    );

    await _onboardingService.saveProfile(updated);
    await AuthSessionService.instance.startSession(
      email: updated.email,
      role: updated.role,
    );

    if (_isRecipient && _hipaaConsentAccepted) {
      await ComplianceApiService.instance.recordConsent(
        email: updated.email,
        consentType: ComplianceApiService.consentTypeHealthSubmit,
      );
      if (_doctorReportPath != null && _doctorReportPath!.isNotEmpty) {
        await ComplianceApiService.instance.upsertHealthRecord(
          recordType: 'doctor_report',
          title: 'Doctor report',
          fileRef: _documentService.fileLabel(_doctorReportPath),
        );
      }
      if (_conditionVideoPath != null && _conditionVideoPath!.isNotEmpty) {
        await ComplianceApiService.instance.upsertHealthRecord(
          recordType: 'condition_video',
          title: 'Condition introduction video',
          fileRef: _documentService.fileLabel(_conditionVideoPath),
        );
      }
      await ComplianceApiService.instance.recordAudit(
        action: 'write',
        resourceType: 'health_record',
        details: 'edit_profile_health_docs',
      );
    }

    final roleLabel = switch (updated.role) {
      UserRole.recipient => 'Recipient',
      UserRole.ngoPartner => 'Verified NGO Partner',
      UserRole.donor => 'Donor',
    };
    await _addressService.saveAddress(
      ProfileAddress(
        roleLabel: roleLabel,
        zipCode: updated.zipCode,
        city: updated.city,
        state: updated.state,
        name: updated.fullName,
      ),
    );

    if (_isNgo) {
      NgoPartnerService.instance.activateSessionFromProfile(updated);
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.t('profile.editSaved'))),
    );
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('profile.editProfile')),
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
                        validator: (value) =>
                            value == null || value.trim().isEmpty
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
                        validator: (value) =>
                            value == null || value.trim().isEmpty
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
                        enabled: _manualAddressEntry ||
                            _zipController.text.isNotEmpty,
                        validator: (value) {
                          final zip = value?.trim() ?? '';
                          if (zip.length != 5 || int.tryParse(zip) == null) {
                            return loc.t('onboarding.zipInvalid');
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _cityController,
                        decoration: InputDecoration(
                          labelText: loc.t('onboarding.city'),
                        ),
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
                  isUploaded: _idDocumentPath.trim().isNotEmpty,
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
                  const SizedBox(height: 24),
                  HipaaConsentCheckbox(
                    value: _hipaaConsentAccepted,
                    errorText: _hipaaConsentError,
                    onChanged: (value) {
                      setState(() {
                        _hipaaConsentAccepted = value ?? false;
                        if (_hipaaConsentAccepted) _hipaaConsentError = null;
                      });
                    },
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
                : const Icon(Icons.save_outlined),
            label: Text(
              _isSubmitting
                  ? loc.t('common.saving')
                  : loc.t('profile.saveProfile'),
            ),
          ),
        ),
      ),
    );
  }
}
