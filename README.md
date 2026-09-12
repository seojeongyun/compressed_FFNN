# Compressed FFNN

## Overview

경량화된 Fully-Connected Neural Network(FFNN)의 연산을 효율적으로 수행하기 위해 **Verilog HDL 기반 Fully-Connected Layer Hardware Architecture**를 설계한 프로젝트입니다.

Software 단계에서 Quantization, Pruning, Knowledge Distillation, Low-Rank Approximation 등의 모델 경량화 기법에 따른 성능 변화를 분석하고, 이 중 **Low-Rank Approximation으로 분해된 weight matrix의 연산 특성을 Hardware Architecture에 반영**했습니다.

특히 기존 Low-Rank Approximation에 학습 가능한 parameter를 적용한 **Learning-based Low-Rank Approximation**을 사용하고, 분해된 weight matrix를 효율적으로 연산할 수 있도록 Compressed Fully-Connected Layer를 Verilog HDL로 설계하여 RTL Simulation을 통해 검증했습니다.

---

## Model Compression & Hardware Design

본 연구는 Software Model Compression과 Hardware Design을 다음과 같이 연결합니다.

```text
Fully-Connected Neural Network
              │
              ▼
      Model Compression
              │
    ┌─────────┼─────────┐
    │         │         │
Quantization Pruning   LRA
                        │
                        ▼
             Learning-based LRA
                        │
                        ▼
              Weight Decomposition
                        │
                        ▼
        Compressed Fully-Connected
             Hardware Layer
                        │
                        ▼
                  Verilog HDL
                        │
                        ▼
                RTL Simulation
```

Quantization, Pruning 등의 기법은 Software 환경에서 모델 경량화 효과를 분석하기 위해 사용했으며, **RTL Hardware Architecture는 Low-Rank Approximation으로 분해된 Fully-Connected Layer를 중심으로 설계**했습니다.

---

## Low-Rank Approximation

Fully-Connected Layer의 weight matrix는 다음과 같이 표현할 수 있습니다.

```text
y = Wx + b
```

Low-Rank Approximation에서는 기존 weight matrix `W`를 두 개의 낮은 rank를 가지는 matrix로 분해합니다.

```text
W ≈ UV

Original FC Layer

        W
x ──────────────▶ y


Low-Rank FC Layer

        V             U
x ──────────▶ h ──────────▶ y
```

기존 weight matrix를 더 작은 두 개의 matrix로 분해함으로써 Fully-Connected Layer에서 저장해야 하는 weight parameter 수를 줄일 수 있습니다.

---

## Learning-based Low-Rank Approximation

일반적인 SVD 기반 Low-Rank Approximation은 학습이 완료된 weight matrix를 singular value decomposition을 통해 분해합니다.

본 프로젝트에서는 단순한 matrix decomposition에 그치지 않고, 분해된 matrix를 **학습 가능한 parameter로 구성하여 Fine-tuning하는 Learning-based Low-Rank Approximation**을 적용했습니다.

```text
Pre-trained Weight
        │
        ▼
       SVD
        │
        ▼
Low-Rank Matrices
      U / V
        │
        ▼
   Fine-tuning
        │
        ▼
Learned Low-Rank
   Parameters
```

이를 통해 parameter 수를 줄이면서 기존 Fully-Connected Network의 inference performance를 최대한 유지하도록 구성했습니다.

---

## Hardware Architecture

Low-Rank Approximation이 적용된 Fully-Connected Layer에서는 하나의 weight matrix multiplication이 두 단계의 matrix multiplication으로 변환됩니다.

```text
Input
  │
  ▼
┌─────────────────────┐
│ Compressed FC Layer │
│                     │
│   Low-Rank Matrix V │
│          │          │
│          ▼          │
│  Intermediate Data  │
│          │          │
│          ▼          │
│   Low-Rank Matrix U │
│          │          │
└──────────┼──────────┘
           ▼
         Output
```

이러한 연산 구조를 Hardware에서 처리할 수 있도록 **Compressed Fully-Connected Layer를 Verilog HDL로 구현**했습니다.

### Fully-Connected Operation

각 Fully-Connected Layer에서는 입력 feature와 weight 간 Multiply-Accumulate 연산을 수행합니다.

```text
Input Feature
     │
     ▼
Weight × Input
     │
     ▼
 Accumulate
     │
     ▼
FC Layer Output
```

Low-Rank Approximation 적용 후에는 분해된 두 weight matrix에 대해 순차적으로 FC 연산을 수행합니다.

```text
Input
  │
  ▼
FC Operation #1
  │
  ▼
Intermediate Feature
  │
  ▼
FC Operation #2
  │
  ▼
Output
```

---

## Quantization

Hardware에서 neural network 연산을 수행하기 위해 weight와 activation을 제한된 bit-width로 표현합니다.

```text
Floating-Point Value
        │
        ▼
    Quantization
        │
        ▼
Fixed-Point / Integer
  Representation
        │
        ▼
   Hardware Input
```

Bit-width를 줄이면 weight를 저장하기 위한 memory requirement와 arithmetic hardware cost를 줄일 수 있지만, quantization error로 인해 inference accuracy가 감소할 수 있습니다.

본 연구에서는 이러한 **bit-width와 inference performance 사이의 trade-off**를 분석하여 경량화된 Fully-Connected Network의 Hardware 구현에 활용했습니다.

---

## Model Compression Analysis

Hardware Architecture 설계에 앞서 다양한 model compression technique이 FFNN의 parameter 수와 inference performance에 미치는 영향을 분석했습니다.

### Quantization

Weight와 activation의 numerical precision을 줄여 memory requirement와 연산 비용을 감소시키는 방법을 분석했습니다.

### Pruning

중요도가 낮은 weight 또는 neuron을 제거하여 network parameter를 줄이는 방법을 분석했습니다.

Structured / Unstructured Pruning에 따른 network compression 특성을 비교했습니다.

### Knowledge Distillation

Teacher Network의 prediction 정보를 Student Network 학습에 활용하여 작은 network에서도 inference performance를 유지할 수 있는 방법을 분석했습니다.

### Low-Rank Approximation

Fully-Connected Layer의 weight matrix를 낮은 rank를 갖는 matrix로 분해하여 parameter 수를 줄이고, 이를 실제 Hardware Architecture에 적용했습니다.

> Quantization, Pruning, Knowledge Distillation 등의 기법은 Software 기반 모델 경량화 분석에 사용했으며, Verilog HDL 기반 Hardware Architecture는 Low-Rank Approximation으로 분해된 Fully-Connected Layer의 연산 구조를 중심으로 설계했습니다.

---

## RTL Verification

설계한 Compressed Fully-Connected Layer는 **RTL Simulation을 통해 기능을 검증**했습니다.

```text
Input Data
    │
    ├──────────────────────┐
    │                      │
    ▼                      ▼
Software Reference     Verilog RTL
    │                      │
    ▼                      ▼
Expected Output        RTL Output
    │                      │
    └──────── Compare ─────┘
```

Software에서 계산한 reference output과 RTL Simulation 결과를 비교하여 Low-Rank Fully-Connected 연산이 Hardware에서도 동일하게 수행되는지 검증했습니다.

---

## Research Flow

본 프로젝트의 전체 연구 흐름은 다음과 같습니다.

```text
Baseline FFNN
     │
     ▼
Model Compression Analysis
     │
     ├── Quantization
     ├── Pruning
     ├── Knowledge Distillation
     └── Low-Rank Approximation
                    │
                    ▼
        Learning-based LRA
                    │
                    ▼
        Weight Matrix Decomposition
                    │
                    ▼
      Compressed FC Hardware Design
                    │
                    ▼
              Verilog HDL
                    │
                    ▼
             RTL Simulation
```

---

## Publication

본 프로젝트의 연구 결과는 다음 논문으로 발표되었습니다.

**Design of Lightweight Fully-Connected Network in Hardware Using Learning-Based Low-Rank Approximation and Quantization Techniques**

* Journal: The Transactions of the Korean Institute of Electrical Engineers
* Volume: 74
* Issue: 1
* Pages: 149–163
* Year: 2025

본 연구에서는 Quantization, Knowledge Distillation, Pruning, Low-Rank Approximation 등의 경량화 기법을 분석하고, Learning-based Low-Rank Approximation을 적용한 Fully-Connected Network를 위한 Hardware Architecture를 Verilog HDL로 설계했습니다.

---

## Key Features

* **Verilog HDL-based Fully-Connected Layer**  
  경량화된 Fully-Connected Network를 위한 RTL Hardware Architecture 설계

* **Learning-based Low-Rank Approximation**  
  SVD로 분해한 weight matrix를 Fine-tuning하여 경량화 이후 inference performance 보완

* **Low-Rank Hardware Architecture**  
  분해된 weight matrix의 연산 구조를 반영한 Compressed Fully-Connected Layer 설계

* **Model Compression Analysis**  
  Quantization, Pruning, Knowledge Distillation, Low-Rank Approximation의 경량화 특성 분석

* **Quantized Hardware Operation**  
  제한된 bit-width의 weight와 activation을 이용한 Hardware 연산

* **RTL Verification**  
  Software reference와 Verilog HDL Simulation 결과 비교를 통한 기능 검증

---

## Tech Stack

`Verilog HDL` · `RTL Design` · `Python` · `PyTorch` · `Quantization` · `Low-Rank Approximation` · `Model Compression`
