import 'package:dago_valley_explore_tv/app/core/usecases/no_param_usecase.dart';
import 'package:dago_valley_explore_tv/domain/entities/payload/housing_response.dart';
import 'package:dago_valley_explore_tv/domain/repositories/house_repository.dart';

class FetchHousingDataUseCase extends NoParamUseCase<HousingResponse> {
  final HouseRepository _repository;

  FetchHousingDataUseCase(this._repository);

  @override
  Future<HousingResponse> execute() {
    return _repository.fetchHousingData();
  }
}
