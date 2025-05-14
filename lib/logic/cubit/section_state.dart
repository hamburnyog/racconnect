part of 'section_cubit.dart';

sealed class SectionState {
  const SectionState();
}

final class SectionInitial extends SectionState {}

final class SectionLoading extends SectionState {}

final class SectionError extends SectionState {
  final String error;
  const SectionError(this.error);
}

final class SectionSuccess extends SectionState {
  final SectionModel sectionModel;
  const SectionSuccess(this.sectionModel);
}

final class GetAllSectionSuccess extends SectionState {
  final List<SectionModel> sectionModels;
  const GetAllSectionSuccess(this.sectionModels);
}
