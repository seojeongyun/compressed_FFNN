# Compressed FFNN

## Overview

MNIST handwritten digit classification을 수행하는 **Feed-Forward Neural Network(FFNN)**를 대상으로 다양한 **Model Compression 기법을 적용하고 성능 변화를 비교한 프로젝트**입니다.

기본 FFNN 모델에 대해 Quantization, Pruning, Low-Rank Approximation을 적용하여 모델의 parameter 및 numerical precision을 줄이고, 경량화 과정에서 발생하는 정확도 저하를 분석했습니다.

특히 단순히 모델 크기를 줄이는 것뿐만 아니라, **경량화 방법에 따라 정확도와 압축률이 어떻게 달라지는지 비교**하는 것을 목표로 실험을 진행했습니다.

---

## Baseline Model

MNIST 이미지를 입력으로 사용하는 Fully Connected Neural Network를 baseline으로 사용했습니다.

```text
MNIST Image
  28 × 28
     │
     ▼
   Flatten
     │
     ▼
784-D Input
     │
     ▼
Linear Layer
  784 → 50
     │
     ▼
Linear Layer
   50 → 100
     │
     ▼
Linear Layer
   100 → 10
     │
     ▼
Digit Classification
     0 ~ 9
```

모델 구조는 다음과 같습니다.

| Layer | Input | Output |
|---|---:|---:|
| FC1 | 784 | 50 |
| FC2 | 50 | 100 |
| FC3 | 100 | 10 |

각 Linear Layer의 weight를 대상으로 다양한 compression technique을 적용했습니다.

---

## Model Compression

본 프로젝트에서는 다음과 같은 모델 경량화 기법을 실험했습니다.

```text
Baseline FFNN
     │
     ├── Quantization
     │      ├── PTQ
     │      └── QAT
     │
     ├── Pruning
     │      ├── Structured
     │      └── Unstructured
     │
     └── Low-Rank Approximation
            └── SVD
```

각 기법을 적용한 뒤 원본 모델과 비교하여 classification accuracy와 compression effect를 분석했습니다.

---

## Quantization

Quantization은 모델의 weight 및 activation을 낮은 bit-width로 표현하여 **memory usage와 arithmetic cost를 줄이는 방법**입니다.

본 프로젝트에서는 다음 두 방식을 비교했습니다.

### Post-Training Quantization

학습이 완료된 floating-point model에 quantization을 적용하는 **PTQ(Post-Training Quantization)**를 실험했습니다.

```text
FP32 Model
    │
    ▼
Quantization
    │
    ▼
Low-Precision Model
```

추가적인 model training 없이 quantization을 적용할 수 있다는 장점이 있지만, quantization error가 직접적으로 모델의 accuracy에 영향을 줄 수 있습니다.

### Quantization-Aware Training

학습 과정에서 quantization effect를 반영하는 **QAT(Quantization-Aware Training)**도 적용했습니다.

```text
Floating-Point Model
        │
        ▼
 Fake Quantization
        │
        ▼
 Forward / Backward
        │
        ▼
Quantization-Aware Training
        │
        ▼
 Low-Precision Model
```

Quantization에 의해 발생하는 numerical error를 학습 과정에서 모델이 보정할 수 있도록 구성했습니다.

### PTQ vs QAT

실험 결과 QAT가 PTQ보다 높은 classification accuracy를 유지했습니다.

| Method | Accuracy |
|---|---:|
| PTQ | 0.9384 |
| QAT | **0.9395** |

QAT를 통해 quantization effect를 학습 과정에 반영함으로써 PTQ 대비 accuracy degradation을 줄일 수 있음을 확인했습니다.

---

## Pruning

Pruning은 중요도가 낮은 weight 또는 neuron을 제거하여 network의 parameter를 줄이는 방법입니다.

본 프로젝트에서는 **L1 Norm 기반 중요도 평가**를 사용하여 Structured Pruning과 Unstructured Pruning을 비교했습니다.

### Unstructured Pruning

개별 weight의 magnitude를 기준으로 중요도가 낮은 weight를 제거합니다.

```text
Weight Matrix
     │
     ▼
L1 Magnitude
     │
     ▼
Remove Small Weights
     │
     ▼
Sparse Weight Matrix
```

Weight 단위로 pruning을 수행하기 때문에 비교적 세밀하게 parameter를 제거할 수 있습니다.

### Structured Pruning

Neuron 또는 channel과 같은 구조 단위로 parameter를 제거합니다.

```text
Fully Connected Layer
        │
        ▼
Neuron Importance
        │
        ▼
Remove Neurons
        │
        ▼
Smaller Dense Layer
```

실험에서는 동일한 pruning 목적에서 **Unstructured L1 Pruning이 Structured L1 Pruning보다 accuracy 유지 측면에서 유리한 경향**을 확인했습니다.

---

## Low-Rank Approximation

Fully Connected Layer의 weight matrix에 대해 **Singular Value Decomposition(SVD)**을 적용하여 Low-Rank Approximation을 수행했습니다.

Weight matrix `W`를 다음과 같이 분해합니다.

```text
W = U Σ Vᵀ
```

전체 singular value를 사용하는 대신 중요한 singular value만 유지하여 weight matrix를 근사합니다.

```text
Original Weight Matrix
          │
          ▼
         SVD
          │
    ┌─────┼─────┐
    ▼     ▼     ▼
    U     Σ     Vᵀ
          │
          ▼
  Rank Reduction
          │
          ▼
Low-Rank Approximation
```

기존 Fully Connected Layer의 weight matrix를 두 개의 작은 matrix multiplication으로 분해하여 parameter 수를 줄일 수 있습니다.

### Compression Result

첫 번째 Fully Connected Layer에 Low-Rank Approximation을 적용한 실험에서 약 **21.27%의 parameter를 제거하면서 accuracy는 약 0.92%p 감소**했습니다.

이는 일부 accuracy degradation을 허용할 경우 SVD 기반 factorization으로 network parameter를 효과적으로 줄일 수 있음을 보여줍니다.

---

## Learnable Clipping

낮은 bit-width quantization에서는 activation 또는 weight의 dynamic range가 quantization error에 큰 영향을 줍니다.

고정된 clipping range를 사용하는 대신 clipping threshold `α`를 학습 가능한 parameter로 두어, 학습 과정에서 적절한 quantization range를 찾도록 구성했습니다.

```text
Input
  │
  ▼
Clipping Range α
  │
  ▼
Quantization
  │
  ▼
Low-Bit Representation
```

```text
Large α
 → Wide Dynamic Range
 → Large Quantization Step

Small α
 → Strong Clipping
 → Smaller Quantization Step
```

따라서 clipping loss와 quantization error 사이의 trade-off를 학습 과정에서 조정할 수 있도록 실험했습니다.

---

## Compression Strategy

전체 경량화 과정은 다음과 같이 구성할 수 있습니다.

```text
Baseline FFNN
     │
     ▼
Model Compression
     │
     ├── Quantization
     │      ├── PTQ
     │      └── QAT
     │
     ├── L1 Pruning
     │      ├── Structured
     │      └── Unstructured
     │
     └── SVD-based
          Low-Rank Approximation
     │
     ▼
Compressed FFNN
     │
     ▼
MNIST Classification
     │
     ▼
Accuracy / Compression Analysis
```

---

## Experiment Results

주요 실험 결과는 다음과 같습니다.

| Compression Method | Result |
|---|---|
| PTQ | Accuracy `0.9384` |
| QAT | Accuracy `0.9395` |
| L1 Pruning | Unstructured 방식이 Structured 방식보다 accuracy 유지에 유리 |
| Low-Rank Approximation | FC Layer parameter 약 `21.27%` 감소 |
| LRA Accuracy Drop | 약 `0.92%p` |

각 기법은 서로 다른 형태의 효율성을 제공합니다.

- Quantization: numerical precision 감소
- Pruning: 불필요한 parameter 제거
- Low-Rank Approximation: weight matrix 연산량 및 parameter 감소

따라서 hardware 또는 deployment 환경의 제약에 따라 적절한 compression 방법을 선택할 수 있습니다.

---

## Repository Structure

```text
compressed_FFNN/
│
└── Compressed FFNN/
    └── ...
```

Repository 내부에는 FFNN baseline 및 model compression 실험 코드가 포함되어 있습니다.

---

## Key Features

* **FFNN Model Compression**  
  MNIST classification FFNN을 대상으로 다양한 경량화 방법 비교

* **PTQ / QAT Comparison**  
  Post-Training Quantization과 Quantization-Aware Training의 accuracy 비교

* **Structured / Unstructured Pruning**  
  L1 Norm 기반 pruning 방식에 따른 성능 변화 분석

* **SVD-based Low-Rank Approximation**  
  Fully Connected Layer의 weight matrix를 저랭크 행렬로 분해하여 parameter 감소

* **Learnable Clipping**  
  Quantization range를 학습 가능한 clipping parameter로 구성

* **Accuracy–Compression Trade-off Analysis**  
  모델 경량화에 따른 parameter 감소와 accuracy degradation 비교

---

## Tech Stack

`Python` · `PyTorch` · `MNIST` · `Model Compression` · `Quantization` · `Pruning` · `SVD`
