import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FilterState extends Equatable {
  final String query; // General search (matches trace, pan, etc)
  final bool onlyErrors;

  const FilterState({this.query = '', this.onlyErrors = false});

  FilterState copyWith({String? query, bool? onlyErrors}) {
    return FilterState(
      query: query ?? this.query,
      onlyErrors: onlyErrors ?? this.onlyErrors,
    );
  }

  @override
  List<Object> get props => [query, onlyErrors];
}

class FilterNotifier extends StateNotifier<FilterState> {
  FilterNotifier() : super(const FilterState());

  void setQuery(String query) => state = state.copyWith(query: query);
  void toggleErrors(bool onlyErrors) => state = state.copyWith(onlyErrors: onlyErrors);
}

final filterProvider = StateNotifierProvider<FilterNotifier, FilterState>((ref) {
  return FilterNotifier();
});
