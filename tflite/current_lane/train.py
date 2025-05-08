import os
import cpuinfo
import time
import torch
import torch.nn as nn
import torch.optim as optim
import torchvision.models as models
from torchvision import transforms, datasets
from torch.utils.data import DataLoader
from tqdm import tqdm

if __name__ == "__main__":
    '''
        Hyperparameters
    '''
    num_epochs = 200
    batch_size = 64
    num_workers = 8
    prefetch_factor = 4

    num_classes = 5
    img_width = 224
    img_height = 224

    lr = 0.0003
    weight_decay = 0.0001
    model_path = "last.pth"
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

    mean = [0.485, 0.456, 0.406]
    std = [0.229, 0.224, 0.225]

    # Model
    model = models.efficientnet_b0(weights="DEFAULT")
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.AdamW(model.parameters(), lr=lr, weight_decay=weight_decay)
    scheduler = optim.lr_scheduler.StepLR(optimizer=optimizer, step_size=5, gamma=0.5)

    # Freezing
    # for param in model.features.parameters():
    #     param.requires_grad = False

    # Classification Classes
    model.classifier = nn.Sequential(
        nn.Dropout(p=0.2, inplace=True),
        nn.Linear(1280, num_classes)
    )

    model.to(device)

    '''
        DataLoader
    '''
    # Data Augmentation
    augmentation = transforms.Compose([

    ])

    # Data Transformation
    train_transform = transforms.Compose([
        augmentation,
        transforms.Resize((img_height, img_width)),
        transforms.ToTensor(),
        transforms.Normalize(mean=mean, std=std)
    ])

    test_transform = transforms.Compose([
        transforms.Resize((img_height, img_width)),
        transforms.ToTensor(),
        transforms.Normalize(mean=mean, std=std)
    ])

    # Dataset
    train_dataset = datasets.ImageFolder("dataset/train", transform=train_transform)
    val_dataset = datasets.ImageFolder("dataset/val", transform=test_transform)
    test_dataset = datasets.ImageFolder("dataset/test", transform=test_transform)

    # DataLoader
    train_loader = DataLoader(
        train_dataset,
        batch_size=batch_size,
        shuffle=True, 
        num_workers=num_workers,
        pin_memory=True,
        persistent_workers=True,
        prefetch_factor=prefetch_factor
    )

    val_loader = DataLoader(
        val_dataset,
        batch_size=batch_size,
        shuffle=False, 
        num_workers=num_workers,
        pin_memory=True
    )

    test_loader = DataLoader(
        test_dataset,
        batch_size=batch_size,
        shuffle=False, 
        num_workers=num_workers,
        pin_memory=True
    )

    '''
        Training
    '''
    # Check model_path to see if required continue training
    start_epoch = 0
    if os.path.exists(model_path):
        try:
            checkpoint = torch.load(model_path)
            
            # 1. Load model state_dict (handle KeyError if 'model_state_dict' doesn't exist)
            model.load_state_dict(checkpoint["model_state_dict"])
            
            # 2. Load optimizer state (if available and optimizer is provided)
            if optimizer is not None and "optimizer_state_dict" in checkpoint:
                optimizer.load_state_dict(checkpoint["optimizer_state_dict"])
            
            # 3. Get epoch (fallback to 0 if missing)
            start_epoch = checkpoint.get("epoch", 0)
            
            print(f"Checkpoint loaded successfully from {model_path}, starting from epoch {start_epoch}.\n")
        
        except Exception as e:
            print(f"Error loading checkpoint: {e}. Starting from scratch.\n")
            start_epoch = 0
    else:
        print(f"No checkpoint found at {model_path}. Starting from scratch.\n")

    # Start Training (last.pth, best.pth)
    print("Training starting. . .\n")
    if device.type == "cuda":
        print("[Using GPU]")
        print(torch.cuda.get_device_name(0))
        print("CUDA Version:", torch.version.cuda)
        print("CUDNN Version:", torch.backends.cudnn.version())
        print()
    else:
        print("[Using CPU]")
        print(cpuinfo.get_cpu_info()['brand_raw'])
        print("CPU Cores:", os.cpu_count())
        print()
    
    start_time = time.time()
    best_val_accuracy = 0.0
    for epoch in range(start_epoch, num_epochs):
        # Training phase
        model.train()
        running_loss = 0.0
        for images, labels in tqdm(train_loader, desc=f"Epoch {epoch+1}/{num_epochs}"):
            images, labels = images.to(device), labels.to(device)
            optimizer.zero_grad()
            outputs = model(images)
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()
            running_loss += loss.item()

        # Validation phase
        model.eval()
        val_loss, correct, total = 0.0, 0, 0
        with torch.no_grad():
            for images, labels in val_loader:
                images, labels = images.to(device), labels.to(device)
                outputs = model(images)
                val_loss += criterion(outputs, labels).item()
                _, predicted = torch.max(outputs.data, 1)
                total += labels.size(0)
                correct += (predicted == labels).sum().item()

        # Update LR scheduler (CRITICAL: AFTER validation)
        scheduler.step()  # StepLR updates here, at epoch end

        # Metrics
        val_accuracy = 100 * correct / total
        print(f"Epoch [{epoch+1}/{num_epochs}]")
        print(f"Train Loss: {running_loss/len(train_loader):.4f}, Val Acc: {val_accuracy:.2f}%")
        print(f"LR: {optimizer.param_groups[0]['lr']:.2e}\n")  # Verify LR changes

        # Save checkpoints
        checkpoint = {
            "epoch": epoch + 1,
            "model_state_dict": model.state_dict(),
            "optimizer_state_dict": optimizer.state_dict(),
            "scheduler_state_dict": scheduler.state_dict(),  # Essential for StepLR
            "best_val_accuracy": best_val_accuracy,
        }
        torch.save(checkpoint, "last.pth")
        
        if val_accuracy > best_val_accuracy:
            best_val_accuracy = val_accuracy
            torch.save(checkpoint, "best.pth")
    
    # Start Testing
    model.eval()
    test_loss = 0.0
    correct = 0
    total = 0
    with torch.no_grad():
        for images, labels in test_loader:
            images, labels = images.to(device), labels.to(device)
            outputs = model(images)
            loss = criterion(outputs, labels)
            test_loss += loss.item()

            _, predicted = torch.max(outputs.data, 1)
            total += labels.size(0)
            correct += (predicted == labels).sum().item()

    print(f"Test Loss: {test_loss/len(test_loader):.4f}, Accuracy: {100 * correct/total:.2f}%\n")

    end_time = time.time()
    execution_time = end_time - start_time
    print("Training completed!")
    print(f"Total execution time: {execution_time/3600:.4f} hours.\n")

    # Export (model.pth)
    model.eval()
    model.classifier = torch.quantization.quantize_dynamic(
        model.classifier,          # Target the classifier only
        {nn.Linear},               # Quantize only Linear layers
        dtype=torch.qint8          # 8-bit quantization
    )

    # Save the model
    torch.save({
        'model_state_dict': model.state_dict(),
    }, "model.pth")
    