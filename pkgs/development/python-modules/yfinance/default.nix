{ lib
, appdirs
, buildPythonPackage
, fetchFromGitHub
, multitasking
, numpy
, pandas
, pythonOlder
, requests
, lxml
}:

buildPythonPackage rec {
  pname = "yfinance";
  version = "0.1.83";
  format = "setuptools";

  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "ranaroussi";
    repo = pname;
    rev = "refs/tags/${version}";
    hash = "sha256-1g2iEIlB+ne01nTMFC6PVvqu3iJ5+De/zDeBdRkYRHg=";
  };

  propagatedBuildInputs = [
    appdirs
    multitasking
    numpy
    pandas
    requests
    lxml
  ];

  # Tests require internet access
  doCheck = false;

  pythonImportsCheck = [
    "yfinance"
  ];

  meta = with lib; {
    description = "Module to doiwnload Yahoo! Finance market data";
    homepage = "https://github.com/ranaroussi/yfinance";
    changelog = "https://github.com/ranaroussi/yfinance/blob/${version}/CHANGELOG.rst";
    license = licenses.asl20;
    maintainers = with maintainers; [ drewrisinger ];
  };
}
