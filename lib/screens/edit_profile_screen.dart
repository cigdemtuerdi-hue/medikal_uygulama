import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/profile_address.dart';
import '../models/user_onboarding_models.dart';
import '../services/auth_session_service.dart';
import '../services/compliance_api_service.dart';
import '../services/ngo_partner_service.dart';
import '../services/onboarding_document_service.dart';
import '../services/onboarding_service.dart';
import '../services/profile_address_service.dart';
import '../widgets/async_state_widgets.dart';
import '../widgets/document_upload_card.dart';
import '../widgets/hipaa_consent_widgets.dart';
import '../widgets/us_address_autocomplete_field.dart';

/// Edit personal details for the signed-in member.
///
/// Unlike signup, fields stay freely editable (ZIP/city/state are never locked)
/// and identity docs are optional unless the user is adding new PHI uploads.
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
  final _streetController = TextEditingController();
  final _orgNameController = TextEditingController();
  final _einController = TextEditingController();

  final _documentService = OnboardingDocumentService();
  final _onboardingService = OnboardingService();
  final _addressService = ProfileAddressService.instance;

  late String _idDocumentPath;
  String? _doctorReportPath;
  String? _conditionVideoPath;
  bool _isSubmitting = false;
  bool _hipaaConsentAccepted = false;
  String? _hipaaConsentError;

  bool get _isRecipient => widget.initialProfile.role == UserRole.recipient;
  bool get _isNgo => widget.initialProfile.role == UserRole.ngoPartner;

  bool get _addingNewHealthDocs {
    final hadDoctor = widget.initialProfile.doctorReportPath?.isNotEmpty == true;
    final hadVideo =
        widget.initialProfile.conditionVideoPath?.isNotEmpty == true;
    final newDoctor = _doctorReportPath != null &&
        _doctorReportPath!.isNotEmpty &&
        _doctorReportPath != widget.initialProfile.doctorReportPath;
    final newVideo = _conditionVideoPath != null &&
        _conditionVideoPath!.isNotEmpty &&
        _conditionVideoPath != widget.initialProfile.conditionVideoPath;
    return (!hadDoctor && newDoctor) || (!hadVideo && newVideo);
  }

  @override
  void initState() {
    super.initState();
    final p = widget.initialProfile;
    _firstNameController.text = p.firstName;
    _lastNameController.text = p.lastName;
    _emailController.text = p.email.isNotEmpty
        ? p.email
        : (AuthSessionService.instance.email ?? '');
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

    _loadSavedStreet();
  }

  Future<void> _loadSavedStreet() async {
    final address = await _addressService.loadCurrentAddress();
    if (!mounted) return;
    if (address.streetAddress != null && address.streetAddress!.isNotEmpty) {
      _streetController.text = address.streetAddress!;
    }
    if (_zipController.text.isEmpty && address.zipCode.isNotEmpty) {
      setState(() {
        _zipController.text = address.zipCode;
        if (_cityController.text.isEmpty) {
          _cityController.text = address.city ?? '';
        }
        if (_stateController.text.isEmpty) {
          _stateController.text = address.state ?? '';
        }
      });
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
    _streetController.dispose();
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

    if (_isRecipient && _addingNewHealthDocs && !_hipaaConsentAccepted) {
      setState(() => _hipaaConsentError = loc.t('hipaa.requiredError'));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('hipaa.requiredError'))),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final email = _emailController.text.trim().toLowerCase();
    final updated = widget.initialProfile.copyWith(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: email,
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

    // Refresh session first (may clear a *different* account's cache), then
    // write this profile so a same-user email change cannot wipe the save.
    await AuthSessionService.instance.ensureLoaded();
    await AuthSessionService.instance.startSession(
      email: updated.email,
      role: updated.role,
      token: AuthSessionService.instance.token,
    );
    await _onboardingService.saveProfile(updated);

    if (_isRecipient && _hipaaConsentAccepted && _addingNewHealthDocs) {
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
    final street = _streetController.text.trim();
    await _addressService.saveAddress(
      ProfileAddress(
        roleLabel: roleLabel,
        zipCode: updated.zipCode,
        city: updated.city,
        state: updated.state,
        name: updated.fullName.trim().isEmpty ? email : updated.fullName,
        streetAddress: street.isEmpty ? null : street,
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
                  helperText: loc.t('profile.editEmailHelper'),
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
                  if (phone.isEmpty) return loc.t('onboarding.phoneInvalid');
                  final digits = phone.replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 10) {
                    return loc.t('onboarding.phoneInvalid');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                loc.t('profile.editAddressSection'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryDeepBlue,
                    ),
              ),
              const SizedBox(height: 12),
              UsAddressAutocompleteField(
                controller: _addressSearchController,
                labelText: loc.t('onboarding.addressOrZip'),
                hintText: loc.t('onboarding.addressHint'),
                onAddressSelected: (suggestion) {
                  setState(() {
                    _addressSearchController.text = suggestion.primaryLine;
                    _zipController.text = suggestion.zipCode;
                    _cityController.text = suggestion.city;
                    _stateController.text = suggestion.state;
                    if (suggestion.streetAddress != null &&
                        suggestion.streetAddress!.isNotEmpty) {
                      _streetController.text = suggestion.streetAddress!;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _streetController,
                decoration: InputDecoration(
                  labelText: loc.t('profile.streetAddress'),
                  hintText: loc.t('profile.streetAddressHint'),
                ),
                textCapitalization: TextCapitalization.words,
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
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? loc.t('profile.cityRequired')
                              : null,
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
                validator: (value) {
                  final state = value?.trim() ?? '';
                  if (state.length != 2) {
                    return loc.t('profile.stateRequired');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              Text(
                loc.t('onboarding.identityVerification'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDeepBlue,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                loc.t('profile.idOptionalHint'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryDeepBlue.withValues(alpha: 0.7),
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
                  isUploaded: _doctorReportPath != null &&
                      _doctorReportPath!.isNotEmpty,
                  fileName: _documentService.fileLabel(_doctorReportPath),
                  onPickFile: _pickDoctorReport,
                ),
                const SizedBox(height: 16),
                DocumentUploadCard(
                  title: loc.t('onboarding.videoTitle'),
                  subtitle: loc.t('onboarding.videoSubtitle'),
                  icon: Icons.videocam_outlined,
                  isUploaded: _conditionVideoPath != null &&
                      _conditionVideoPath!.isNotEmpty,
                  fileName: _documentService.fileLabel(_conditionVideoPath),
                  onPickVideo: _pickConditionVideo,
                ),
                if (_addingNewHealthDocs) ...[
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
            ],
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
