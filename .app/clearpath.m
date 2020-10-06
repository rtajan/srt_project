function clearpath()
    try
        load saved_path.mat
        path(saved_path)
    catch
    end
end