# Changelog

## [3.1.6](https://github.com/xsitarcik/reads/compare/v3.1.5...v3.1.6) (2024-03-09)


### Bug Fixes

* file marked as temp only if not in outputs ([56a9028](https://github.com/xsitarcik/reads/commit/56a9028dc5f0bbd44b83ef35fad67eb05bd3ebff))

## [3.1.5](https://github.com/xsitarcik/reads/compare/v3.1.4...v3.1.5) (2024-03-09)


### Bug Fixes

* replaced index locating with iloc ([8fed537](https://github.com/xsitarcik/reads/commit/8fed5377659983d0ac369005da95271272560bad))

## [3.1.4](https://github.com/xsitarcik/reads/compare/v3.1.3...v3.1.4) (2024-03-09)


### Bug Fixes

* marked temp outputs all steps ([03c445e](https://github.com/xsitarcik/reads/commit/03c445eec9d175ae2adb89c447f911747b622859))

## [3.1.3](https://github.com/xsitarcik/reads/compare/v3.1.2...v3.1.3) (2024-03-03)


### Bug Fixes

* added validation for cutadapt adapters file ([fff224d](https://github.com/xsitarcik/reads/commit/fff224d6c1f1d4f96dc5612a1fccee475a805585))

## [3.1.2](https://github.com/xsitarcik/reads/compare/v3.1.1...v3.1.2) (2024-02-25)


### Bug Fixes

* removed requirement for dynamic parameter ([e0cb37a](https://github.com/xsitarcik/reads/commit/e0cb37a9044a22c1be15675bde1e1cda005d4bf3))

## [3.1.1](https://github.com/xsitarcik/reads/compare/v3.1.0...v3.1.1) (2024-02-04)


### Bug Fixes

* correct parsing for optional cutadapt params ([ed7cb61](https://github.com/xsitarcik/reads/commit/ed7cb61b92974da0486f426bcc474cd9b841a068))

## [3.1.0](https://github.com/xsitarcik/reads/compare/v3.0.0...v3.1.0) (2024-01-26)


### Features

* extended schema to dynamically request other elements ([6d0e243](https://github.com/xsitarcik/reads/commit/6d0e243b77c9d1dfe32e218a571dc75afeb6bff7))


### Bug Fixes

* default schema values from config are for description only as intended, to prevent user from magic situations ([2b3b39b](https://github.com/xsitarcik/reads/commit/2b3b39b5a2b986b08c7801ce2a514418eca13135))

## [3.0.0](https://github.com/xsitarcik/reads/compare/v2.0.1...v3.0.0) (2024-01-25)


### ⚠ BREAKING CHANGES

* changed workflow to be method specific

### Features

* changed workflow to be method specific ([43ae243](https://github.com/xsitarcik/reads/commit/43ae24301194d4816774952ff96c7cc6664cf075))
* config edited to be independent and clear for reads only ([27546a4](https://github.com/xsitarcik/reads/commit/27546a4631d344a87d8a2b0730d076f1710b0225))

## [2.0.1](https://github.com/xsitarcik/reads/compare/v2.0.0...v2.0.1) (2024-01-05)


### Bug Fixes

* removed read group as it is not required ([d5c24fb](https://github.com/xsitarcik/reads/commit/d5c24fb344970c176a27b401d8e54b81e3757670))

## [2.0.0](https://github.com/xsitarcik/reads/compare/v1.1.0...v2.0.0) (2024-01-05)


### ⚠ BREAKING CHANGES

* renamed config elements with reads__ prefix to prevent conflicts

### Features

* renamed config elements with reads__ prefix to prevent conflicts ([10419fb](https://github.com/xsitarcik/reads/commit/10419fb82491d98d2b9a20a9b1767dbbb7fb9646))

## [1.1.0](https://github.com/xsitarcik/reads/compare/v1.0.0...v1.1.0) (2024-01-04)


### Features

* added read group ([3a44417](https://github.com/xsitarcik/reads/commit/3a444178e36223897f92ba3dd90968a9b1f1c662))

## 1.0.0 (2024-01-04)


### Features

* added read processing workflow ([f204726](https://github.com/xsitarcik/reads/commit/f20472652f67a8fd89f26431c82e2aafd828f877))
