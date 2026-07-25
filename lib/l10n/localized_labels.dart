import '../models/contact_inquiry.dart';
import '../models/donation_models.dart';
import 'app_localizations.dart';

String locCondition(AppLocalizations loc, ItemCondition condition) {
  return switch (condition) {
    ItemCondition.excellent => loc.t('condition.excellent'),
    ItemCondition.good => loc.t('condition.good'),
    ItemCondition.fair => loc.t('condition.fair'),
    ItemCondition.needsRepair => loc.t('condition.needsRepair'),
    ItemCondition.notDonatable => loc.t('condition.notDonatable'),
  };
}

String locInquirySubject(AppLocalizations loc, InquirySubject subject) {
  return switch (subject) {
    InquirySubject.sponsorship => loc.t('inquiry.subject.sponsorship'),
    InquirySubject.partnership => loc.t('inquiry.subject.partnership'),
    InquirySubject.general => loc.t('inquiry.subject.general'),
  };
}

String locDmeType(AppLocalizations loc, DmeType type) {
  return switch (type) {
    DmeType.wheelchair => loc.t('dme.type.wheelchair'),
    DmeType.walker => loc.t('dme.type.walker'),
    DmeType.hospitalBed => loc.t('dme.type.hospitalBed'),
    DmeType.oxygenEquipment => loc.t('dme.type.oxygenEquipment'),
    DmeType.nebulizer => loc.t('dme.type.nebulizer'),
    DmeType.commode => loc.t('dme.type.commode'),
    DmeType.showerChair => loc.t('dme.type.showerChair'),
    DmeType.other => loc.t('dme.type.other'),
  };
}

String locWoundCareType(AppLocalizations loc, WoundCareType type) {
  return switch (type) {
    WoundCareType.sterileDressings => loc.t('woundCare.type.sterileDressings'),
    WoundCareType.compressionWraps => loc.t('woundCare.type.compressionWraps'),
    WoundCareType.gauzePads => loc.t('woundCare.type.gauzePads'),
    WoundCareType.adhesiveBandages => loc.t('woundCare.type.adhesiveBandages'),
    WoundCareType.woundCleansers => loc.t('woundCare.type.woundCleansers'),
    WoundCareType.other => loc.t('woundCare.type.other'),
  };
}

String locCategory(AppLocalizations loc, DonationCategory category) {
  return switch (category) {
    DonationCategory.dme => loc.t('common.categoryDme'),
    DonationCategory.woundCare => loc.t('common.categoryWoundCare'),
  };
}

String locRequestStatus(AppLocalizations loc, RequestStatus status) {
  return switch (status) {
    RequestStatus.pending => loc.t('requests.statusPending'),
    RequestStatus.shipped => loc.t('requests.statusShipped'),
    RequestStatus.delivered => loc.t('requests.statusDelivered'),
  };
}

String locHandoffOption(AppLocalizations loc, HandoffOption option) {
  return switch (option) {
    HandoffOption.pickupOnly => loc.t('handoff.pickupOnly'),
    HandoffOption.assistanceAvailable => loc.t('handoff.assistanceAvailable'),
    HandoffOption.meetupPossible => loc.t('handoff.meetupPossible'),
  };
}

String locHandoffOptionHint(AppLocalizations loc, HandoffOption option) {
  return switch (option) {
    HandoffOption.pickupOnly => loc.t('handoff.pickupOnlyHint'),
    HandoffOption.assistanceAvailable =>
      loc.t('handoff.assistanceAvailableHint'),
    HandoffOption.meetupPossible => loc.t('handoff.meetupPossibleHint'),
  };
}
