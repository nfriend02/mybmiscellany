# mybmiscellany

Play & Learn. 학습 툴의 안정감과 게임 허브의 활기를 한 Flutter 앱에 둔 작업실입니다. 웹과 모바일은 같은 `lib/features` 모듈을 사용합니다.

## 로컬 실행

```bash
flutter pub get
flutter run -d web-server --web-hostname localhost --web-port 8080 --dart-define-from-file=secrets/defines.json
```

`secrets/.env`에 넣은 키는 `secrets/defines.json`으로 옮겨 로컬 실행에만 넘깁니다. 두 파일 모두 git에 올리지 않습니다. 브라우저에서 http://localhost:8080 을 엽니다. Chrome으로 바로 보려면 같은 `--dart-define-from-file`을 `flutter run -d chrome`에 붙입니다. Google 로그인이 거절되면 Cloud 콘솔의 승인된 자바스크립트 원본에 `http://localhost:8080`을 추가합니다.

Android, iOS, Windows 타깃도 같은 프로젝트에서 실행할 수 있습니다. Windows에서 플러그인 빌드가 심볼릭 링크를 요구하면 개발자 모드를 켭니다.

## 화면

메인 화면은 **게임 센터**와 **학습 툴박스**로 나뉩니다.

- 데스크톱: 사이드바
- 모바일: 상단 바와 하단 네비게이션, 메뉴는 서랍

기본색은 블루와 화이트이고, 포인트는 네온 그린, 퍼플, 오렌지입니다. 본문은 Inter와 Roboto, 메뉴 영문 타이틀은 Orbitron과 Press Start 2P입니다.

## 모듈 추가

1. `lib/features/<feature-name>/` 폴더를 만듭니다. 폴더 이름은 소문자와 하이픈만 사용합니다.
2. 화면은 `FeatureNameWidget.dart`, 계산과 저장 로직은 `featureNameService.dart`에 둡니다.
3. 게임 모듈은 같은 폴더에 `<gameName>.css` 토큰 파일을 두고, 시작 스플래시를 넣습니다.
4. `lib/core/registry/featureRegistry.dart`에 모듈을 등록합니다. `featureType`은 폴더 이름과 같아야 하고, 주소는 `/<featureType>` 입니다.
5. 화면은 `FeatureFrame`으로 감쌉니다. 기록 목록의 `HistoryCard`, 메뉴 아이콘 `IconSet`, 앱 껍데기 `Layout`이 함께 적용됩니다. 텍스트, 음성, 파일 입력은 `InputBox`를 사용합니다.
6. 결과 저장은 `saveResult`를 호출합니다. `results` 문서의 `featureType`에 폴더 이름이 들어갑니다.

게임 아이콘은 레지스트리에 제안한 뒤 리뷰에서 확정합니다. 현재 Lucky Canon은 🎯 입니다.

## 게임 플러그인

게임 폴더 예:

```
lib/features/lucky-canon/
  LuckyCanonWidget.dart
  luckyCanonService.dart
  luckyCanon.css
```

랭킹은 `scores`, 게임 소개는 `games`에 저장합니다. 아이템과 대전은 `FirestoreGateway`의 `saveItem`, `saveUserItem`, `saveMatch`를 사용합니다.

## Firebase

Firestore 컬렉션은 `users`, `results`, `games`, `scores`, `items`, `userItems`, `matches` 입니다.

```
users ──< results
users ──< scores >── games
users ──< userItems >── items >── games
users ──< matches >── games
```

웹 클라이언트 설정은 `lib/core/firebase/firebaseOptions.dart`에 있습니다. 앱은 연결에 실패해도 화면의 기록은 이 기기에 남깁니다. 규칙 초안은 `firebase/firestore.rules`이며, 공개 배포 전에 인증을 붙이고 삭제 권한을 좁혀야 합니다.

## Pull Request

외부 모듈 PR에는 기능 설명, UI 스크린샷, DB 변경, 테스트가 포함되어야 합니다. GitHub Actions가 `flutter analyze`와 `flutter test`를 실행합니다.

## 배포

Vercel 프로젝트 주소는 https://mybmiscellany.vercel.app 입니다. 저장소와 배포 연결은 나중에 진행합니다.
