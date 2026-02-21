# ImageFeed

> **SwiftUI + async/await + Clean Architecture로 구현한 대용량 이미지 피드 앱**  
---

## 🎯 프로젝트 목표

### 핵심 목표
**"기능 추가자(Feature Developer)"에서 "시스템 설계자(System Architect)"로의 전환**

### 구체적 프로젝트 사양

#### 1. 아키텍처 설계
- **Clean Architecture 3계층 분리**
  - Domain Layer: 순수 Swift 비즈니스 로직 (UIKit/SwiftUI 의존 없음)
  - Data Layer: Repository 패턴 기반 데이터 소싱
  - Presentation Layer: SwiftUI + MVVM
- **Protocol 기반 Dependency Injection**
  - 테스트 가능한 코드 구조
  - Mock/Stub을 통한 외부 의존성 격리
- **단위 테스트 커버리지 80%+ 목표**

#### 2. 동시성 처리
- **Swift 6 Structured Concurrency**
  - async/await 기반 비동기 이미지 로딩
  - TaskGroup을 활용한 병렬 다운로드
  - Actor를 통한 Thread-safe 캐싱
- **Sendable 프로토콜 준수** (Data Race 제로)

#### 3. 성능 최적화
- **3-Tier 이미지 캐싱 시스템**
  - Memory Cache: NSCache (50MB 제한)
  - Disk Cache: FileManager (200MB 제한, LRU)
  - Network: Unsplash API
- **무한 스크롤 피드** (Pagination)
- **Instruments를 통한 성능 측정**
  - 메모리 누수 0개 증명
  - 캐시 히트율 85%+ 목표

#### 4. 주요 기능
- 이미지 피드 무한 스크롤
- 이미지 상세 보기 (확대/축소)
- 검색 기능
- 좋아요 기능 (로컬 상태 관리)
- 다크 모드 지원

---

## 🚀 Performance Goals

### 대용량 데이터 처리 목표
**"10,000개 이미지를 로딩해도 원활한 스크롤 성능 유지"**

#### 측정 가능한 성능 지표
| 항목 | 목표 | 측정 도구 |
|------|------|----------|
| **메모리 사용량** | 10,000개 이미지 로딩 시 50MB 이하 유지 | Instruments (Allocations) |
| **스크롤 성능** | 무한 스크롤 시 60fps 유지 | Instruments (Core Animation) |
| **캐시 히트율** | 85% 이상 달성 | 커스텀 로깅 + Instruments |
| **메모리 누수** | 0개 (Zero Leaks) | Instruments (Leaks) |
| **초기 로딩 속도** | 첫 30개 이미지 2초 이내 렌더링 | 수동 측정 |

#### 성능 최적화 전략
1. **메모리 관리**
   - LazyVStack을 통한 필요 시점 렌더링
   - 화면 밖 이미지는 메모리에서 해제 (NSCache의 자동 메모리 경고 처리)
   - 썸네일 우선 로딩 후 고해상도 지연 로딩

2. **스크롤 성능**
   - 메인 스레드 블로킹 최소화 (모든 이미지 처리는 백그라운드)
   - Actor 기반 캐시 접근으로 동시성 안전성 확보
   - prefetching을 통한 사전 다운로드

3. **네트워크 최적화**
   - 병렬 다운로드 최대 5개 제한 (서버 부하 고려)
   - 실패 시 exponential backoff 재시도
   - 네트워크 도달 불가 시 디스크 캐시 우선 사용

---

## 📚 프로젝트 시작 전 학습 내용 (Claude 멘토링)

### Phase 1: Core Swift & Memory Management (Week 1-2, 완료)

#### Week 1: 메모리 모델 Deep Dive
**학습 내용:**
- Stack vs Heap 메모리 할당 메커니즘
  - struct가 class 프로퍼티에 포함될 때 Heap 할당
  - Array의 실제 데이터는 Heap 저장, struct는 포인터만 보유
- ARC(Automatic Reference Counting) 내부 동작
  - retain/release 호출 시점
  - weak의 SideTable 메커니즘
  - unowned의 성능 트레이드오프
- Copy-on-Write(COW) 최적화
  - Reference Count > 1일 때만 복사 발생
  - `isKnownUniquelyReferenced` 메커니즘

**핵심 검증 질문:**
- "struct를 class 프로퍼티로 가지면, 그 struct는 Stack에 있는가 Heap에 있는가?"
- "weak var를 사용하면 성능이 느려지는 정확한 이유는?"

#### Week 2: SwiftUI 내부 메커니즘
**학습 내용:**
- Attribute Graph 의존성 추적 시스템
  - DAG(Directed Acyclic Graph) 구조
  - getter 호출 시점에 의존성 엣지 등록
  - setter 호출 시 의존 노드만 선별적 무효화
- @State Storage 수명 주기
  - View struct가 아닌 Attribute Graph 노드가 소유
  - 조건부 View의 노드 생명주기 관리
- Property Wrapper 비교
  - @State: Graph 노드 소유, 자체 Storage
  - @Binding: 부모 @State Storage 포인터
  - @StateObject: ObservableObject 인스턴스 소유
  - @Observable: ObservationRegistrar 프로퍼티 단위 추적

**핵심 검증 질문:**
- "@State가 View struct 내부에 있는데, View가 재생성되어도 값이 유지되는 이유는?"
- "if/else 조건 변경 시 Attribute Graph에서 어떤 일이 일어나는가?"

### Week 3: Clean Architecture 설계 (진행 중)

**학습 예정:**
- Clean Architecture 3계층(Presentation/Domain/Data) 분리
- Domain Layer의 플랫폼 독립성 (iOS/macOS/Server 재사용 가능)
- Repository Pattern + Dependency Inversion Principle
- UseCase를 통한 비즈니스 로직 캡슐화

**예습 완료:**
- Domain Layer가 UIKit에 의존하면 안 되는 이유 (플랫폼 종속성, 테스트 복잡도)
- Repository를 Protocol로 추상화하는 이유 (DIP, Mock 주입)

---

## 🛠 기술 스택

### Core
- **Language:** Swift 6
- **UI Framework:** SwiftUI
- **Architecture:** Clean Architecture + MVVM
- **Concurrency:** async/await, Actor, TaskGroup
- **DI:** Protocol-based Dependency Injection

### Libraries
- **Networking:** URLSession (순수 구현)
- **Image Loading:** AsyncImage + 커스텀 캐싱
- **Testing:** XCTest

### Tools
- **Performance:** Instruments
- **Version Control:** Git + GitHub

---

## 📖 학습 방법론

### 메커니즘 우선 학습 (Mechanism-First Learning)
모든 학습은 "어떻게(How)"가 아닌 **"왜(Why)"**와 **"어떤 원리(Mechanism)"**로 동작하는지 이해하는 것을 목표로 함.

**예시:**
```
Swift 코드: @State private var counter = 0
    ↓
컴파일러: Property Wrapper 전개
    ↓
런타임: SwiftUI Storage(Heap)에 값 저장, View struct에는 포인터만
    ↓
Attribute Graph: getter 호출 시 의존성 엣지 등록
```

### 역질문을 통한 검증
멘토(Claude)가 제시한 역질문을 통해 학습 내용을 검증하고, "오해"와 "실제 메커니즘"을 대조하여 정확한 이해 확립.

### 프로젝트 연결 학습
모든 이론은 실제 포트폴리오 기능 구현으로 연결하여 학습.
