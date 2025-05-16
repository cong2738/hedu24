# UVM (Universal Verification Methodology)

## 개요
- **UVM**은 SystemVerilog 기반의 하드웨어 설계 검증을 위한 표준화된 방법론
- 복잡한 SoC, ASIC, FPGA 설계의 기능 검증을 체계적으로 수행할 수 있도록 지원
- Accellera에서 표준화하였으며, OVM, VMM의 장점을 통합

## 주요 특징
- **재사용성**: 모듈화된 컴포넌트로 다양한 프로젝트에 재사용 가능
- **확장성**: 계층적 구조로 복잡한 시스템도 쉽게 확장
- **자동화**: 시뮬레이션, 커버리지, 랜덤화 등 자동화 지원
- **표준화**: 여러 툴과 벤더에서 호환

## 기본 구조

### 1. Testbench 계층 구조
- **Test**: 시나리오 정의, 환경 설정
- **Environment (env)**: 전체 검증 환경 구성
- **Agent**: DUT와의 인터페이스 담당
- **Driver**: DUT에 신호 전달
- **Sequencer**: 시퀀스(트랜잭션) 생성 및 관리
- **Monitor**: DUT의 출력을 관찰 및 수집
- **Scoreboard**: 결과 비교 및 검증

### 2. 주요 클래스
- `uvm_test`
- `uvm_env`
- `uvm_agent`
- `uvm_driver`
- `uvm_sequencer`
- `uvm_monitor`
- `uvm_scoreboard`
- `uvm_sequence`, `uvm_sequence_item`

## 주요 개념

### Factory 패턴
- 객체 생성 시 유연하게 타입을 바꿀 수 있도록 지원

### Configuration
- 파라미터, 객체 등을 계층적으로 설정 및 전달

### Transaction 기반 검증
- 신호가 아닌 트랜잭션(데이터 구조) 단위로 DUT와 통신

### Randomization & Constraints
- 입력값을 랜덤하게 생성, 제약조건 설정 가능

### Coverage
- 기능 커버리지, 코드 커버리지 등 다양한 커버리지 지원

### Messaging & Reporting
- 로그, 에러, 경고 등 다양한 메시지 출력 지원

## 참고 자료
- [Accellera UVM 공식 문서](https://accellera.org/downloads/standards/uvm)
- [UVM Cookbook](https://verificationacademy.com/cookbook/uvm)
- [Verification Academy](https://verificationacademy.com/)

---

> **UVM은 복잡한 하드웨어 검증을 위한 강력한 프레임워크다. 구조와 개념을 이해하고, 예제 코드를 직접 작성해보며 익히는 것이 중요하다.**

# study

## uvm
- sequenser의 역할: sequence class와 다른 클래스 간의 중재자(arviter) 역할. 이것도 나름 통신이니 신호 순서 중재를 해줄 필요가 있으니 사이에 끼어서 조율해줌  
![alt text](/img/image.png)  
- uvm_analysis_imp, uvm_analysis_port:  
![alt text](/img/tlm-put.gif)
![alt text](/img/image-1.png)
- phase:  
![alt text](/img/image.png)

## workplace
- vcs명령어, UVM:  
    vcs -full64 -sverilog -ntb_opts uvm-1.2 ./경로/파일명 ./경로/파일명
    ./simv +UVM_TESTNAME=test -l ./경로/파일명  
    tip: vcs는 파일 변경사항이 없으면 컴파일을 새로 안함
- make:  
    1976년 Stuart Feldman이 개발한 빌드 자동화 소프트웨어. 
    - makefile: 
    - 변수 콜 방법: $(변수명)
## synopsys verdy  
- 버디를 사용하기 전에 시뮬레이션 데이터를 모두 ".fsdb"로 저장해야한다  
    그때 사용하는 시스템 베릴로그 기능은 dump이며 fsdbDump를 쓴다.
    > **$fsdbDumpcars(0); // 모든정보를 수집할거다  
    $fsdbDumpfile("wave.fsdb"); // "파일명"에다가 수집한정보를 저장(dump)할것  **

# Project