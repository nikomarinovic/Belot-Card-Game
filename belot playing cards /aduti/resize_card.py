from PIL import Image
import os

# Folder gdje su karte
input_folder = "./karte"
output_folder = "./karte_resized"
os.makedirs(output_folder, exist_ok=True)

# Target physical size in inches
TARGET_WIDTH_INCHES = 7  # e.g., 7 inches
TARGET_HEIGHT_INCHES = 11  # e.g., 11 inches
TARGET_DPI = 300

# Convert physical size to pixels
TARGET_WIDTH = int(TARGET_WIDTH_INCHES * TARGET_DPI)
TARGET_HEIGHT = int(TARGET_HEIGHT_INCHES * TARGET_DPI)

for filename in os.listdir(input_folder):
    if filename.lower().endswith((".png", ".jpg", ".jpeg")):
        img_path = os.path.join(input_folder, filename)
        img = Image.open(img_path).convert("RGB")

        # Determine scaling factor to fit the image inside target size
        scale_w = TARGET_WIDTH / img.width
        scale_h = TARGET_HEIGHT / img.height
        scale = min(scale_w, scale_h)  # Preserve aspect ratio

        new_size = (int(img.width * scale), int(img.height * scale))
        img_resized = img.resize(new_size, Image.LANCZOS)

        # Create a canvas of target size with white background
        canvas = Image.new("RGB", (TARGET_WIDTH, TARGET_HEIGHT), (255, 255, 255))
        x = (TARGET_WIDTH - img_resized.width) // 2
        y = (TARGET_HEIGHT - img_resized.height) // 2
        canvas.paste(img_resized, (x, y))

        # Save with consistent DPI for physical size
        canvas.save(os.path.join(output_folder, filename), dpi=(TARGET_DPI, TARGET_DPI))

print("Gotovo! Sve karte su fizički iste veličine i spremljene u:", output_folder)
